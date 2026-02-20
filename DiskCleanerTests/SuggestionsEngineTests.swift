import XCTest
@testable import DiskCleaner

@MainActor
final class SuggestionsEngineTests: XCTestCase {

    private var engine: SuggestionsEngine!

    override func setUp() async throws {
        try await super.setUp()
        engine = SuggestionsEngine()
    }

    func testDetectFromTreeFindsKnownWasters() {
        // Build a tree that mimics ~/Library with known waster paths
        let derivedData = FileNodeBuilder.dir(
            "DerivedData",
            path: "/Users/test/Library/Developer/Xcode/DerivedData",
            children: [FileNodeBuilder.file("build.o", size: 5000, path: "/Users/test/Library/Developer/Xcode/DerivedData/build.o")]
        )
        let xcode = FileNodeBuilder.dir(
            "Xcode",
            path: "/Users/test/Library/Developer/Xcode",
            children: [derivedData]
        )
        let developer = FileNodeBuilder.dir(
            "Developer",
            path: "/Users/test/Library/Developer",
            children: [xcode]
        )
        let caches = FileNodeBuilder.dir(
            "Caches",
            path: "/Users/test/Library/Caches",
            children: [FileNodeBuilder.file("cache.db", size: 3000, path: "/Users/test/Library/Caches/cache.db")]
        )
        let logs = FileNodeBuilder.dir(
            "Logs",
            path: "/Users/test/Library/Logs",
            children: [FileNodeBuilder.file("app.log", size: 1000, path: "/Users/test/Library/Logs/app.log")]
        )
        let library = FileNodeBuilder.dir(
            "Library",
            path: "/Users/test/Library",
            children: [developer, caches, logs]
        )
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        let results = engine.detectFromTree(root: root)

        let categories = results.map(\.category)
        XCTAssertTrue(categories.contains(.xcodeDerivedData))
        XCTAssertTrue(categories.contains(.userCaches))
        XCTAssertTrue(categories.contains(.logs))
    }

    func testDetectFromTreeExcludesTrashedNodes() {
        let cacheFile = FileNodeBuilder.file("cache.db", size: 3000, path: "/Users/test/Library/Caches/cache.db")
        let caches = FileNodeBuilder.dir(
            "Caches",
            path: "/Users/test/Library/Caches",
            children: [cacheFile]
        )
        caches.isTrashed = true
        let library = FileNodeBuilder.dir("Library", path: "/Users/test/Library", children: [caches])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        let results = engine.detectFromTree(root: root)
        let hasCaches = results.contains { $0.category == .userCaches }
        XCTAssertFalse(hasCaches, "Trashed directories should be excluded")
    }

    func testDetectFromTreeExcludesHiddenNodes() {
        let cacheFile = FileNodeBuilder.file("cache.db", size: 3000, path: "/Users/test/Library/Caches/cache.db")
        let caches = FileNodeBuilder.dir(
            "Caches",
            path: "/Users/test/Library/Caches",
            children: [cacheFile]
        )
        caches.isHidden = true
        let library = FileNodeBuilder.dir("Library", path: "/Users/test/Library", children: [caches])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        let results = engine.detectFromTree(root: root)
        let hasCaches = results.contains { $0.category == .userCaches }
        XCTAssertFalse(hasCaches, "Hidden directories should be excluded")
    }

    func testDetectFromTreeExcludesZeroSizeNodes() {
        let caches = FileNodeBuilder.dir(
            "Caches",
            path: "/Users/test/Library/Caches",
            children: []
        )
        let library = FileNodeBuilder.dir("Library", path: "/Users/test/Library", children: [caches])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        let results = engine.detectFromTree(root: root)
        let hasCaches = results.contains { $0.category == .userCaches }
        XCTAssertFalse(hasCaches, "Zero-size directories should be excluded")
    }

    func testDetectFromTreeReturnsCorrectSizes() {
        let cacheFile = FileNodeBuilder.file("cache.db", size: 5000, path: "/Users/test/Library/Caches/cache.db")
        let caches = FileNodeBuilder.dir(
            "Caches",
            path: "/Users/test/Library/Caches",
            children: [cacheFile]
        )
        let library = FileNodeBuilder.dir("Library", path: "/Users/test/Library", children: [caches])
        let root = FileNodeBuilder.tree("test", path: "/Users/test", children: [library])

        let results = engine.detectFromTree(root: root)
        let cachesResult = results.first { $0.category == .userCaches }
        XCTAssertEqual(cachesResult?.size, 5000)
    }

    func testDetectFromTreeWithNilRoot() {
        let results = engine.detectFromTree(root: nil)
        XCTAssertTrue(results.isEmpty)
    }
}
