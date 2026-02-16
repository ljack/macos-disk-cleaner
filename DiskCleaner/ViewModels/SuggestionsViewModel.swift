import Foundation

/// Manages smart suggestions state
@MainActor
@Observable
final class SuggestionsViewModel {
    var suggestions: [SpaceWaster] = []
    var isDetecting = false

    private let engine = SuggestionsEngine()

    var totalWastedSpace: Int64 {
        suggestions.reduce(0) { $0 + $1.size }
    }

    var formattedTotalWaste: String {
        ByteCountFormatter.string(fromByteCount: totalWastedSpace, countStyle: .file)
    }

    func detect(scanRoot: FileNode?) {
        isDetecting = true

        // Tree-based analysis: find known wasters + node_modules from the scanned tree
        let knownWasters = engine.detectFromTree(root: scanRoot)
        let nodeModules = scanRoot.map { findNodeModules(in: $0) } ?? []

        suggestions = (knownWasters + nodeModules).sorted { $0.size > $1.size }
        isDetecting = false
    }

    /// Recursively find node_modules directories in the scanned tree.
    private func findNodeModules(in node: FileNode) -> [SpaceWaster] {
        guard !node.isTrashed && !node.isHidden else { return [] }

        if node.isDirectory && node.name == "node_modules" {
            return [SpaceWaster(
                category: .nodeModules,
                url: node.url,
                size: node.size,
                itemCount: node.descendantCount
            )]
        }

        var results: [SpaceWaster] = []
        for child in node.children where child.isDirectory {
            results.append(contentsOf: findNodeModules(in: child))
        }
        return results
    }
}
