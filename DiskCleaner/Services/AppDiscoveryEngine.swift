import AppKit

/// Actor that discovers installed applications and their associated files.
actor AppDiscoveryEngine {
    private let fileManager = FileManager.default

    /// Discover all installed apps with their associated files.
    func discoverApps() async -> [InstalledApp] {
        let home = fileManager.homeDirectoryForCurrentUser
        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            home.appendingPathComponent("Applications"),
        ]

        var apps: [InstalledApp] = []

        for dir in searchDirs {
            guard fileManager.fileExists(atPath: dir.path) else { continue }
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents where url.pathExtension == "app" {
                if let app = await buildApp(from: url) {
                    apps.append(app)
                }
            }
        }

        return apps.sorted { $0.totalSize > $1.totalSize }
    }

    /// Build an InstalledApp from a .app bundle URL.
    func buildApp(from bundleURL: URL) async -> InstalledApp? {
        let name = bundleURL.deletingPathExtension().lastPathComponent
        let bundle = Bundle(url: bundleURL)
        let bundleIdentifier = bundle?.bundleIdentifier

        let bundleSize = directorySize(bundleURL)

        let icon = await MainActor.run {
            NSWorkspace.shared.icon(forFile: bundleURL.path)
        }

        var app = InstalledApp(
            name: name,
            bundleIdentifier: bundleIdentifier,
            bundleURL: bundleURL,
            bundleSize: bundleSize,
            icon: icon
        )

        app.associatedFiles = findAssociatedFiles(
            bundleIdentifier: bundleIdentifier,
            appName: name
        )

        return app
    }

    /// Find all associated files for an app across ~/Library subdirectories.
    private func findAssociatedFiles(bundleIdentifier: String?, appName: String) -> [AssociatedFile] {
        let home = fileManager.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")
        var files: [AssociatedFile] = []

        // Directories searched by both bundle ID and app name
        let nameMatchDirs: [(String, AssociatedFileCategory)] = [
            ("Application Support", .applicationSupport),
            ("Caches", .caches),
            ("Logs", .logs),
        ]

        for (subdir, category) in nameMatchDirs {
            let baseDir = library.appendingPathComponent(subdir)

            if let bundleId = bundleIdentifier {
                let dir = baseDir.appendingPathComponent(bundleId)
                if fileManager.fileExists(atPath: dir.path) {
                    let size = directorySize(dir)
                    if size > 0 {
                        files.append(AssociatedFile(url: dir, size: size, category: category))
                    }
                }
            }

            let dir = baseDir.appendingPathComponent(appName)
            if fileManager.fileExists(atPath: dir.path) {
                // Avoid duplicates if bundleId matches app name
                if !files.contains(where: { $0.url == dir }) {
                    let size = directorySize(dir)
                    if size > 0 {
                        files.append(AssociatedFile(url: dir, size: size, category: category))
                    }
                }
            }
        }

        // Directories searched by bundle ID only
        if let bundleId = bundleIdentifier {
            let bundleIdOnlyPaths: [(URL, AssociatedFileCategory)] = [
                (library.appendingPathComponent("Preferences/\(bundleId).plist"), .preferences),
                (library.appendingPathComponent("Saved Application State/\(bundleId).savedState"), .savedState),
                (library.appendingPathComponent("Containers/\(bundleId)"), .containers),
                (library.appendingPathComponent("HTTPStorages/\(bundleId)"), .httpStorages),
                (library.appendingPathComponent("WebKit/\(bundleId)"), .webKit),
            ]

            for (url, category) in bundleIdOnlyPaths {
                guard fileManager.fileExists(atPath: url.path) else { continue }

                let size: Int64
                if url.pathExtension == "plist" {
                    size = url.fileSize
                } else {
                    size = directorySize(url)
                }

                if size > 0 {
                    files.append(AssociatedFile(url: url, size: size, category: category))
                }
            }
        }

        return files.sorted { $0.size > $1.size }
    }

    /// Calculate total size of a directory.
    private func directorySize(_ url: URL) -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey]
            ) else { continue }

            if values.isDirectory != true {
                totalSize += Int64(values.totalFileAllocatedSize ?? 0)
            }
        }

        return totalSize
    }
}
