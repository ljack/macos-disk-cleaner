import Foundation

/// Actor that detects known space-wasting directories from the scanned file tree.
/// In the sandboxed App Store build, this uses in-memory tree analysis instead of
/// direct filesystem access, since only user-granted directories are accessible.
actor SuggestionsEngine {
    /// Known space-waster path suffixes to match against the scanned tree.
    private static let knownWasters: [(suffix: String, category: SpaceWasterCategory)] = [
        ("Library/Developer/Xcode/DerivedData", .xcodeDerivedData),
        ("Library/Developer/Xcode/Archives", .xcodeArchives),
        ("Library/Developer/Xcode/iOS DeviceSupport", .xcodeDeviceSupport),
        ("Library/Caches", .userCaches),
        (".cache", .dotCache),
        ("Library/Logs", .logs),
        ("Library/Caches/Homebrew", .homebrewCache),
        ("Library/Containers/com.docker.docker", .dockerData),
        (".Trash", .trash),
    ]

    /// Detect space wasters by walking the scanned file tree.
    /// Matches known waster paths against directory nodes in the tree.
    @MainActor
    func detectFromTree(root: FileNode?) -> [SpaceWaster] {
        guard let root else { return [] }
        var results: [SpaceWaster] = []

        for (suffix, category) in Self.knownWasters {
            if let node = findNodeByPathSuffix(root: root, suffix: suffix) {
                guard !node.isTrashed && !node.isHidden && node.size > 0 else { continue }
                results.append(SpaceWaster(
                    category: category,
                    url: node.url,
                    size: node.size,
                    itemCount: node.descendantCount
                ))
            }
        }

        return results
    }

    /// Walk the tree to find a node whose path ends with the given suffix.
    @MainActor
    private func findNodeByPathSuffix(root: FileNode, suffix: String) -> FileNode? {
        let targetPath = suffix
        return findNode(in: root, matching: targetPath)
    }

    @MainActor
    private func findNode(in node: FileNode, matching suffix: String) -> FileNode? {
        if node.url.path.hasSuffix(suffix) && node.isDirectory {
            return node
        }
        for child in node.children where child.isDirectory {
            if let found = findNode(in: child, matching: suffix) {
                return found
            }
        }
        return nil
    }
}
