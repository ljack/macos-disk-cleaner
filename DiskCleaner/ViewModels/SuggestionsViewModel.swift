import Foundation

/// Manages smart suggestions state
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
        Task {
            let results = await engine.detectAll(scanRoot: scanRoot)
            await MainActor.run {
                self.suggestions = results
                self.isDetecting = false
            }
        }
    }
}
