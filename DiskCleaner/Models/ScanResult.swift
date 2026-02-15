import Foundation

/// Wraps a completed scan with metadata
struct ScanResult {
    let root: FileNode
    let scanDate: Date
    let duration: TimeInterval
    let totalFiles: Int
    let totalDirectories: Int
    let accessMode: DiskAccessMode

    var totalItems: Int { totalFiles + totalDirectories }
}
