import XCTest
@testable import DiskCleaner

@MainActor
final class SuggestionsViewModelTests: XCTestCase {

    private var viewModel: SuggestionsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = SuggestionsViewModel()
    }

    func testTotalWastedSpaceSumsCorrectly() {
        // Build a tree with known waster paths
        let cacheFile = FileNodeBuilder.file("cache.db", size: 3000, path: "/Users/test/Library/Caches/cache.db")
        let caches = FileNodeBuilder.dir("Caches", path: "/Users/test/Library/Caches", children: [cacheFile])
        let logFile = FileNodeBuilder.file("app.log", size: 2000, path: "/Users/test/Library/Logs/app.log")
        let logs = FileNodeBuilder.dir("Logs", path: "/Users/test/Library/Logs", children: [logFile])
        let library = FileNodeBuilder.dir("Library", path: "/Users/test/Library", children: [caches, logs])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        viewModel.detect(scanRoot: root)

        XCTAssertEqual(viewModel.totalWastedSpace, 5000)
    }

    func testFormattedTotalWasteIsNonEmpty() {
        let cacheFile = FileNodeBuilder.file("cache.db", size: 1024 * 1024, path: "/Users/test/Library/Caches/cache.db")
        let caches = FileNodeBuilder.dir("Caches", path: "/Users/test/Library/Caches", children: [cacheFile])
        let library = FileNodeBuilder.dir("Library", path: "/Users/test/Library", children: [caches])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        viewModel.detect(scanRoot: root)

        XCTAssertFalse(viewModel.formattedTotalWaste.isEmpty)
    }

    func testFindNodeModulesDetection() {
        let nmFile = FileNodeBuilder.file("lodash.js", size: 5000, path: "/Users/test/project/node_modules/lodash.js")
        let nodeModules = FileNodeBuilder.dir("node_modules", path: "/Users/test/project/node_modules", children: [nmFile])
        let project = FileNodeBuilder.dir("project", path: "/Users/test/project", children: [nodeModules])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [project])

        viewModel.detect(scanRoot: root)

        let hasNodeModules = viewModel.suggestions.contains { $0.category == .nodeModules }
        XCTAssertTrue(hasNodeModules, "Should detect node_modules directories")
    }

    func testDetectWithNilScanRootClearsSuggestions() {
        viewModel.detect(scanRoot: nil)
        XCTAssertTrue(viewModel.suggestions.isEmpty)
        XCTAssertEqual(viewModel.totalWastedSpace, 0)
    }

    func testSuggestionsAreSortedBySizeDescending() {
        let cacheFile = FileNodeBuilder.file("cache.db", size: 1000, path: "/Users/test/Library/Caches/cache.db")
        let caches = FileNodeBuilder.dir("Caches", path: "/Users/test/Library/Caches", children: [cacheFile])
        let logFile = FileNodeBuilder.file("app.log", size: 5000, path: "/Users/test/Library/Logs/app.log")
        let logs = FileNodeBuilder.dir("Logs", path: "/Users/test/Library/Logs", children: [logFile])
        let library = FileNodeBuilder.dir("Library", path: "/Users/test/Library", children: [caches, logs])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        viewModel.detect(scanRoot: root)

        // Verify sorted descending by size
        for i in 0..<(viewModel.suggestions.count - 1) {
            XCTAssertGreaterThanOrEqual(
                viewModel.suggestions[i].size,
                viewModel.suggestions[i + 1].size,
                "Suggestions should be sorted by size descending"
            )
        }
    }
}
