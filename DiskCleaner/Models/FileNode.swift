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

    /// Number of descendants (files + directories) in subtree
    var descendantCount: Int = 0

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

    /// Recalculate this node's size and propagate to parent
    func recalculateSizeUpward() {
        if isDirectory {
            size = children.reduce(0) { $0 + $1.size }
            descendantCount = children.reduce(0) { $0 + $1.descendantCount + 1 }
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
}

extension FileNode: Hashable {
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
