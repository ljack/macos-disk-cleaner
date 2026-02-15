import Foundation
import AppKit

extension URL {
    /// Get the system icon for this file/directory
    var systemIcon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }

    /// Check if this URL is a directory
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }

    /// Get file size in bytes
    var fileSize: Int64 {
        let values = try? resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
        return Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
    }
}
