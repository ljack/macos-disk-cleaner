import Foundation

/// Sort options for the app list
enum AppSortOrder: String, CaseIterable {
    case totalSize = "Total Size"
    case name = "Name"
    case appSize = "App Size"
    case dataSize = "Data Size"
}

/// Manages the app uninstaller feature state
@Observable
final class AppUninstallerViewModel {
    var apps: [InstalledApp] = []
    var isScanning = false
    var selectedApp: InstalledApp?
    var searchText = ""
    var sortOrder: AppSortOrder = .totalSize

    // Uninstall confirmation flow
    var appToUninstall: InstalledApp?
    var showingUninstallConfirmation = false
    var isUninstalling = false
    var uninstallError: String?

    private let engine = AppDiscoveryEngine()

    /// Filtered and sorted apps for display
    var displayedApps: [InstalledApp] {
        var result = apps

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        switch sortOrder {
        case .totalSize:
            result.sort { $0.totalSize > $1.totalSize }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .appSize:
            result.sort { $0.bundleSize > $1.bundleSize }
        case .dataSize:
            result.sort { $0.associatedSize > $1.associatedSize }
        }

        return result
    }

    /// Discover all installed apps
    func discoverApps() {
        isScanning = true
        Task {
            let discovered = await engine.discoverApps()
            await MainActor.run {
                self.apps = discovered
                self.isScanning = false
            }
        }
    }

    /// Build an InstalledApp from a bundle URL and request uninstall
    func requestUninstallFromTree(bundleURL: URL) {
        Task {
            guard let app = await engine.buildApp(from: bundleURL) else { return }
            await MainActor.run {
                self.requestUninstall(app)
            }
        }
    }

    /// Request uninstall for an app (shows confirmation)
    func requestUninstall(_ app: InstalledApp) {
        appToUninstall = app
        uninstallError = nil
        showingUninstallConfirmation = true
    }

    /// Perform the uninstall using the shared DeletionService
    func performUninstall(using deletionService: DeletionService, onComplete: (@MainActor (_ originalURLs: [URL], _ trashedURLs: [URL], _ app: InstalledApp) -> Void)? = nil) {
        guard let app = appToUninstall else { return }
        isUninstalling = true
        uninstallError = nil

        Task {
            do {
                // Collect all URLs to trash: app bundle + associated files
                let urls = [app.bundleURL] + app.associatedFiles.map(\.url)

                let trashedURLs = try await deletionService.moveToTrash(urls: urls)

                await MainActor.run {
                    self.apps.removeAll { $0.id == app.id }
                    if self.selectedApp?.id == app.id {
                        self.selectedApp = nil
                    }
                    self.isUninstalling = false
                    self.showingUninstallConfirmation = false
                    self.appToUninstall = nil
                    onComplete?(urls, trashedURLs, app)
                }
            } catch {
                await MainActor.run {
                    self.uninstallError = error.localizedDescription
                    self.isUninstalling = false
                }
            }
        }
    }

    /// Cancel uninstall
    func cancelUninstall() {
        showingUninstallConfirmation = false
        appToUninstall = nil
        uninstallError = nil
    }
}
