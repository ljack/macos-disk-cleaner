import Foundation

/// Scope for a temporary directory-exclusion rule.
enum ExclusionRuleScope: String, Codable, CaseIterable, Identifiable {
    case allModes
    case userDirectoryOnly
    case fullDiskOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allModes:
            return "All Scan Modes"
        case .userDirectoryOnly:
            return "Home Directory Only"
        case .fullDiskOnly:
            return "Full Disk Only"
        }
    }

    func applies(to mode: DiskAccessMode) -> Bool {
        switch self {
        case .allModes:
            return true
        case .userDirectoryOnly:
            return mode == .userDirectory
        case .fullDiskOnly:
            return mode == .fullDisk
        }
    }

    static func currentMode(_ mode: DiskAccessMode) -> ExclusionRuleScope {
        switch mode {
        case .userDirectory:
            return .userDirectoryOnly
        case .fullDisk:
            return .fullDiskOnly
        }
    }
}

/// User-defined temporary exclusion rule for a directory.
struct ExcludedDirectoryRule: Codable, Identifiable, Hashable {
    let id: UUID
    var path: String
    var remainingScans: Int
    var scope: ExclusionRuleScope
    let createdAt: Date
    var lastMatchedAt: Date?
    var totalMatches: Int

    init(
        id: UUID = UUID(),
        path: String,
        remainingScans: Int,
        scope: ExclusionRuleScope,
        createdAt: Date = Date(),
        lastMatchedAt: Date? = nil,
        totalMatches: Int = 0
    ) {
        self.id = id
        self.path = path
        self.remainingScans = max(0, remainingScans)
        self.scope = scope
        self.createdAt = createdAt
        self.lastMatchedAt = lastMatchedAt
        self.totalMatches = totalMatches
    }

    var isActive: Bool {
        remainingScans > 0
    }

    var normalizedPath: String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}

/// Sendable scan-time snapshot of an active exclusion rule.
struct ScanExclusionRule: Sendable, Hashable {
    let id: UUID
    let normalizedPath: String
}

/// Wraps a completed scan with metadata
struct ScanResult {
    let root: FileNode
    let scanDate: Date
    let duration: TimeInterval
    let totalFiles: Int
    let totalDirectories: Int
    let accessMode: DiskAccessMode
    let matchedExclusionRuleIDs: Set<UUID>

    var totalItems: Int { totalFiles + totalDirectories }
}
