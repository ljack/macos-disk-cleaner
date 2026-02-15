import Foundation

/// Manages smart suggestions state
@MainActor
@Observable
final class SuggestionsViewModel {
    var suggestions: [SpaceWaster] = []
    var isDetecting = false

    private let engine = SuggestionsEngine()
    private var detectTask: Task<Void, Never>?

    var totalWastedSpace: Int64 {
        suggestions.reduce(0) { $0 + $1.size }
    }

    var formattedTotalWaste: String {
        ByteCountFormatter.string(fromByteCount: totalWastedSpace, countStyle: .file)
    }

    func detect(scanRoot: FileNode?) {
        detectTask?.cancel()
        isDetecting = true

        detectTask = Task {
            // Tree walk on MainActor (fast, in-memory) — avoids cross-actor FileNode access
            let nodeModules = scanRoot.map { self.findNodeModules(in: $0) } ?? []
            guard !Task.isCancelled else { return }

            let fsResults = await engine.detectFilesystemWasters()
            guard !Task.isCancelled else { return }
            self.suggestions = (fsResults + nodeModules).sorted { $0.size > $1.size }
            self.isDetecting = false
        }
    }

    /// Recursively find node_modules directories in the scanned tree.
    /// Runs on MainActor so FileNode reads are safe. Checks cancellation per directory.
    private func findNodeModules(in node: FileNode) -> [SpaceWaster] {
        guard !Task.isCancelled else { return [] }
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
            if Task.isCancelled { break }
            results.append(contentsOf: findNodeModules(in: child))
        }
        return results
    }
}
