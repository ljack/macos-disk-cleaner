import AppKit
import Foundation

/// Checks and prompts for Full Disk Access permission.
enum PermissionService {
    /// Check if the app has Full Disk Access by trying to read a protected directory
    static func hasFullDiskAccess() -> Bool {
        let testPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mail")
        return FileManager.default.isReadableFile(atPath: testPath.path)
    }

    /// Open System Settings to the Full Disk Access pane
    static func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
