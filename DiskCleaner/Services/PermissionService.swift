import AppKit
import Foundation

/// Provides folder-selection dialogs for sandboxed file access.
/// In the App Store sandbox, all filesystem access beyond the container
/// requires explicit user grants via NSOpenPanel.
enum PermissionService {
    /// Present an NSOpenPanel for the user to choose a scan root folder.
    /// Returns a security-scoped URL if the user makes a selection.
    @MainActor
    static func chooseScanFolder(startingAt suggestedURL: URL? = nil) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        panel.message = "Choose a folder to scan for disk usage."
        panel.treatsFilePackagesAsDirectories = false

        if let suggestedURL {
            panel.directoryURL = suggestedURL
        }

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    /// Present an NSOpenPanel for the user to grant access to a specific directory.
    /// Pre-navigates to the directory so the user just needs to click "Grant Access".
    @MainActor
    static func grantAccessToDirectory(at url: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Grant Access"
        panel.message = "Select \"\(url.lastPathComponent)\" to grant access."
        panel.directoryURL = url.deletingLastPathComponent()

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
