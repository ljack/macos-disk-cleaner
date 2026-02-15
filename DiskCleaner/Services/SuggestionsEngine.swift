import Foundation

/// Actor that detects known space-wasting directories and files.
actor SuggestionsEngine {
    private let fileManager = FileManager.default

    /// Detect all known space wasters. Checks locations concurrently.
    func detectAll(scanRoot: FileNode?) async -> [SpaceWaster] {
        let home = fileManager.homeDirectoryForCurrentUser

        async let xcodeDerived = checkDirectory(
            home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
            category: .xcodeDerivedData
        )
        async let xcodeArchives = checkDirectory(
            home.appendingPathComponent("Library/Developer/Xcode/Archives"),
            category: .xcodeArchives
        )
        async let xcodeDeviceSupport = checkDirectory(
            home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport"),
            category: .xcodeDeviceSupport
        )
        async let userCaches = checkDirectory(
            home.appendingPathComponent("Library/Caches"),
            category: .userCaches
        )
        async let dotCache = checkDirectory(
            home.appendingPathComponent(".cache"),
            category: .dotCache
        )
        async let logs = checkDirectory(
            home.appendingPathComponent("Library/Logs"),
            category: .logs
        )
        async let homebrewCache = checkDirectory(
            home.appendingPathComponent("Library/Caches/Homebrew"),
            category: .homebrewCache
        )
        async let dockerData = checkDirectory(
            home.appendingPathComponent("Library/Containers/com.docker.docker"),
            category: .dockerData
        )
        async let trash = checkDirectory(
            home.appendingPathComponent(".Trash"),
            category: .trash
        )

        let results = await [
            xcodeDerived, xcodeArchives, xcodeDeviceSupport,
            userCaches, dotCache, logs, homebrewCache,
            dockerData, trash
        ]

        // Find node_modules directories from scan tree if available
        var allResults = results.compactMap { $0 }

        if let root = scanRoot {
            let nodeModules = findNodeModules(in: root)
            allResults.append(contentsOf: nodeModules)
        }

        return allResults.sorted { $0.size > $1.size }
    }

    /// Check a single directory, returning a SpaceWaster if it exists and has content
    private func checkDirectory(_ url: URL, category: SpaceWasterCategory) -> SpaceWaster? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let (size, count) = directorySize(url)
        guard size > 0 else { return nil }

        return SpaceWaster(category: category, url: url, size: size, itemCount: count)
    }

    /// Calculate total size and item count of a directory
    private func directorySize(_ url: URL) -> (Int64, Int) {
        var totalSize: Int64 = 0
        var itemCount = 0

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return (0, 0)
        }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey]) else {
                continue
            }
            if values.isDirectory != true {
                totalSize += Int64(values.totalFileAllocatedSize ?? 0)
                itemCount += 1
            }
        }

        return (totalSize, itemCount)
    }

    /// Recursively find node_modules directories in the scanned tree
    private func findNodeModules(in node: FileNode) -> [SpaceWaster] {
        guard !node.isTrashed && !node.isHidden else { return [] }

        var results: [SpaceWaster] = []

        if node.isDirectory && node.name == "node_modules" {
            results.append(SpaceWaster(
                category: .nodeModules,
                url: node.url,
                size: node.size,
                itemCount: node.descendantCount
            ))
            return results // Don't recurse into node_modules
        }

        for child in node.children where child.isDirectory {
            results.append(contentsOf: findNodeModules(in: child))
        }

        return results
    }
}
