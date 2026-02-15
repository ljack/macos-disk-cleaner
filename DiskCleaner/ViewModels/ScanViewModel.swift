import Foundation

/// All possible scan states — drives the scan button's icon and label
enum ScanStatus: Equatable {
    case readyToScan          // First launch, never scanned
    case scanning             // Scan in progress
    case complete             // Just finished (< 5 min ago)
    case resultsAging         // Results 5–60 min old
    case outdated             // Results > 1 hour old
    case stopped              // User cancelled mid-scan
    case failed(String)       // Error occurred

    var label: String {
        switch self {
        case .readyToScan:    return "Scan Now"
        case .scanning:       return "Scanning..."
        case .complete:       return "Scan Complete"
        case .resultsAging:   return "Results Aging"
        case .outdated:       return "Rescan Needed"
        case .stopped:        return "Scan Stopped"
        case .failed:         return "Scan Failed"
        }
    }

    var icon: String {
        switch self {
        case .readyToScan:    return "play.circle.fill"
        case .scanning:       return "progress.indicator"  // placeholder, we use ProgressView
        case .complete:       return "checkmark.circle.fill"
        case .resultsAging:   return "clock.fill"
        case .outdated:       return "exclamationmark.triangle.fill"
        case .stopped:        return "stop.circle.fill"
        case .failed:         return "xmark.circle.fill"
        }
    }

    var subtitle: String? {
        switch self {
        case .readyToScan:    return "Analyze your disk usage"
        case .scanning:       return nil // shown by progress overlay
        case .complete:       return "Results are fresh"
        case .resultsAging:   return "Consider rescanning"
        case .outdated:       return "Results may be stale"
        case .stopped:        return "Partial results shown"
        case .failed(let msg):return msg
        }
    }

    /// Whether clicking the button should start a new scan
    var canStartScan: Bool {
        switch self {
        case .scanning: return false
        default: return true
        }
    }

    /// Whether clicking the button should stop the current scan
    var canStopScan: Bool {
        self == .scanning
    }
}

/// Manages scanning state and progress
@MainActor
@Observable
final class ScanViewModel {
    var isScanning = false
    var scanResult: ScanResult?
    var progress: ScanProgress?
    var errorMessage: String?
    private(set) var wasCancelled = false

    /// TCC-protected directories that were skipped during scan
    var restrictedDirectories: [FileNode] = []
    var isResolvingDirectory = false
    var resolvingDirectoryName: String?

    private let engine = ScanningEngine()
    private var scanTask: Task<Void, Never>?
    private var rescanTask: Task<Void, Never>?
    private var rescanGeneration = 0

    var rootNode: FileNode? {
        scanResult?.root
    }

    /// Computed scan status based on current state
    var status: ScanStatus {
        if isScanning {
            return .scanning
        }
        if let error = errorMessage {
            return .failed(error)
        }
        if wasCancelled && scanResult == nil {
            return .stopped
        }
        guard let result = scanResult else {
            return .readyToScan
        }
        let age = Date().timeIntervalSince(result.scanDate)
        if age < 300 {        // < 5 min
            return .complete
        } else if age < 3600 { // < 1 hour
            return .resultsAging
        } else {
            return .outdated
        }
    }

    func startScan(mode: DiskAccessMode, exclusionRules: [ScanExclusionRule]) {
        guard !isScanning else { return }

        isScanning = true
        wasCancelled = false
        errorMessage = nil
        progress = nil
        scanResult = nil
        restrictedDirectories = []

        let startTime = Date()
        let rootURL = mode.rootURL
        let homeURL = FileManager.default.homeDirectoryForCurrentUser

        scanTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.engine.scan(
                    root: rootURL,
                    homeURL: homeURL,
                    exclusionRules: exclusionRules
                ) { [weak self] progress in
                    self?.progress = progress
                }

                let duration = Date().timeIntervalSince(startTime)
                self.restrictedDirectories = result.pendingDirectories
                self.scanResult = ScanResult(
                    root: result.root,
                    scanDate: Date(),
                    duration: duration,
                    totalFiles: self.progress?.filesScanned ?? 0,
                    totalDirectories: self.progress?.directoriesScanned ?? 0,
                    accessMode: mode,
                    matchedExclusionRuleIDs: result.matchedExclusionRuleIDs
                )
                self.isScanning = false
            } catch is CancellationError {
                self.wasCancelled = true
                self.isScanning = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isScanning = false
            }
        }
    }

    /// Rescan a single TCC-protected directory after user grants access
    func rescanDirectory(_ node: FileNode) {
        rescanTask?.cancel()
        isResolvingDirectory = true
        resolvingDirectoryName = node.name

        rescanGeneration += 1
        let generation = rescanGeneration

        rescanTask = Task {
            do {
                let scannedNode = try await engine.scanSubtree(at: node.url) { _ in }
                guard generation == self.rescanGeneration else { return }

                // Transplant children from scanned result into existing node
                node.children = scannedNode.children
                for child in node.children {
                    child.parent = node
                }
                node.awaitingPermission = false
                node.isPermissionDenied = false
                node.finalizeTree()
                node.parent?.recalculateSizeUpward()
                node.parent?.children.sort { $0.size > $1.size }

                // Remove from restricted list
                self.restrictedDirectories.removeAll { $0.id == node.id }
                self.isResolvingDirectory = false
                self.resolvingDirectoryName = nil
                self.rescanTask = nil
            } catch is CancellationError {
                // Cancelled by a newer rescanDirectory call — don't touch shared state
            } catch {
                guard generation == self.rescanGeneration else { return }
                node.awaitingPermission = false
                node.isPermissionDenied = true

                // Keep in restricted list but update state
                self.isResolvingDirectory = false
                self.resolvingDirectoryName = nil
                self.rescanTask = nil
            }
        }
    }

    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
    }
}
