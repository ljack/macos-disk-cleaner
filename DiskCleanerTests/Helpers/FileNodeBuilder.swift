import Foundation
@testable import DiskCleaner

/// Helper to build test FileNode trees concisely.
enum FileNodeBuilder {
    /// Create a directory node with the given name and children.
    static func dir(
        _ name: String,
        path: String? = nil,
        children: [FileNode] = [],
        size: Int64 = 0
    ) -> FileNode {
        let url = URL(fileURLWithPath: path ?? "/test/\(name)")
        let node = FileNode(url: url, name: name, isDirectory: true, size: size, children: children)
        for child in children {
            child.parent = node
        }
        return node
    }

    /// Create a file node with the given name and size.
    static func file(
        _ name: String,
        size: Int64,
        path: String? = nil
    ) -> FileNode {
        let url = URL(fileURLWithPath: path ?? "/test/\(name)")
        return FileNode(url: url, name: name, isDirectory: false, size: size)
    }

    /// Build a tree from a root directory. Calls finalizeTree() and sets parent references.
    static func tree(
        _ name: String,
        path: String? = nil,
        children: [FileNode]
    ) -> FileNode {
        let root = dir(name, path: path, children: children)
        root.finalizeTree()
        return root
    }
}
