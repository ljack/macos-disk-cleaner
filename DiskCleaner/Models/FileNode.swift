import Foundation

/// A node in the file system tree. Uses class (reference semantics) for efficient
/// large tree handling — avoids copying millions of nodes.
final class FileNode: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    var size: Int64
    var children: [FileNode]
    weak var parent: FileNode?

    /// True if we couldn't read this directory due to permissions
    var isPermissionDenied: Bool = false

    /// True if this is a TCC-protected directory that was skipped during scan
    var awaitingPermission: Bool = false

    /// Number of descendants (files + directories) in subtree
    var descendantCount: Int = 0

    /// True if this node has been moved to Trash
    var isTrashed: Bool = false

    /// The URL of this item in Trash (for restore)
    var trashURL: URL?

    init(url: URL, name: String, isDirectory: Bool, size: Int64 = 0, children: [FileNode] = []) {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.size = size
        self.children = children
    }

    /// Recalculate size from children (bottom-up) and sort children by size descending
    func finalizeTree() {
        for child in children {
            child.finalizeTree()
        }
        if isDirectory {
            size = children.reduce(0) { $0 + $1.size }
            descendantCount = children.reduce(0) { $0 + $1.descendantCount + 1 }
            children.sort { $0.size > $1.size }
        }
    }

    /// Remove a child node and recalculate sizes upward
    func removeChild(_ child: FileNode) {
        children.removeAll { $0.id == child.id }
        recalculateSizeUpward()
    }

    /// Mark this node as trashed and recalculate parent sizes
    func markAsTrashed(trashURL: URL) {
        isTrashed = true
        self.trashURL = trashURL
        parent?.recalculateSizeUpward()
    }

    /// Unmark this node as trashed, re-read size from disk, and recalculate parent sizes
    func unmarkTrashed() {
        isTrashed = false
        trashURL = nil
        if !isDirectory {
            size = url.fileSize
        }
        parent?.recalculateSizeUpward()
    }

    /// Recalculate this node's size and propagate to parent (excludes trashed children)
    func recalculateSizeUpward() {
        if isDirectory {
            let activeChildren = children.filter { !$0.isTrashed }
            size = activeChildren.reduce(0) { $0 + $1.size }
            descendantCount = activeChildren.reduce(0) { $0 + $1.descendantCount + 1 }
        }
        parent?.recalculateSizeUpward()
    }

    /// Human-readable size string
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Fraction of parent's size (for size bars)
    var fractionOfParent: Double {
        guard let parent = parent, parent.size > 0 else { return 1.0 }
        return Double(size) / Double(parent.size)
    }

    /// Find a descendant node matching the given URL by walking the tree path.
    func findNode(at targetURL: URL) -> FileNode? {
        let targetPath = targetURL.standardizedFileURL.path
        let ownPath = url.standardizedFileURL.path

        // Exact match
        if targetPath == ownPath { return self }

        // Target must be under this node
        guard targetPath.hasPrefix(ownPath + "/") || targetPath.hasPrefix(ownPath) else {
            return nil
        }

        // Search children
        for child in children {
            if let found = child.findNode(at: targetURL) {
                return found
            }
        }
        return nil
    }
}

extension FileNode: Hashable {
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
