import Foundation

/// Actor that detects known space-wasting directories and files.
actor SuggestionsEngine {
    private let fileManager = FileManager.default

    /// Detect known filesystem space wasters. Checks locations concurrently.
    func detectFilesystemWasters() async -> [SpaceWaster] {
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

        return results.compactMap { $0 }
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

}
