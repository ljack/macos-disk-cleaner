import Foundation

/// Scope for a temporary directory-exclusion rule.
/// Kept for backward compatibility with persisted rules — all scopes now apply to every scan.
enum ExclusionRuleScope: String, Codable, CaseIterable, Identifiable {
    case allModes
    case userDirectoryOnly
    case fullDiskOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allModes:
            return "All Scans"
        case .userDirectoryOnly:
            return "All Scans"
        case .fullDiskOnly:
            return "All Scans"
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
        scope: ExclusionRuleScope = .allModes,
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
    let scanRootPath: String
    let matchedExclusionRuleIDs: Set<UUID>

    var totalItems: Int { totalFiles + totalDirectories }
}
