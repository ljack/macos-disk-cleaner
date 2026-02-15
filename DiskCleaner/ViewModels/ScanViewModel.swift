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
@Observable
final class ScanViewModel {
    var isScanning = false
    var scanResult: ScanResult?
    var progress: ScanProgress?
    var errorMessage: String?
    private(set) var wasCancelled = false

    private let engine = ScanningEngine()
    private var scanTask: Task<Void, Never>?

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

    func startScan(mode: DiskAccessMode) {
        guard !isScanning else { return }

        isScanning = true
        wasCancelled = false
        errorMessage = nil
        progress = nil
        scanResult = nil

        let startTime = Date()
        let rootURL = mode.rootURL

        scanTask = Task {
            do {
                let root = try await engine.scan(root: rootURL) { [weak self] progress in
                    Task { @MainActor in
                        self?.progress = progress
                    }
                }

                await MainActor.run {
                    let duration = Date().timeIntervalSince(startTime)
                    self.scanResult = ScanResult(
                        root: root,
                        scanDate: Date(),
                        duration: duration,
                        totalFiles: self.progress?.filesScanned ?? 0,
                        totalDirectories: self.progress?.directoriesScanned ?? 0,
                        accessMode: mode
                    )
                    self.isScanning = false
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.wasCancelled = true
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isScanning = false
                }
            }
        }
    }

    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
    }
}
