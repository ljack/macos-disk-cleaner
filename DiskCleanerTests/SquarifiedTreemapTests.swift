import XCTest
@testable import DiskCleaner

final class SquarifiedTreemapTests: XCTestCase {

    func testEmptyNodeReturnsEmptyResult() {
        let root = FileNodeBuilder.tree("root", children: [])
        let rects = SquarifiedTreemap.layout(node: root, bounds: CGRect(x: 0, y: 0, width: 500, height: 500))
        XCTAssertTrue(rects.isEmpty)
    }

    func testSingleChildFillsBounds() {
        let child = FileNodeBuilder.file("only.txt", size: 1000)
        let root = FileNodeBuilder.tree("root", children: [child])

        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let rects = SquarifiedTreemap.layout(node: root, bounds: bounds, maxDepth: 0, minSize: 1)

        XCTAssertEqual(rects.count, 1)
        let r = rects[0].rect
        XCTAssertEqual(r.width, bounds.width, accuracy: 1)
        XCTAssertEqual(r.height, bounds.height, accuracy: 1)
    }

    func testMultipleChildrenTotalAreaMatchesBounds() {
        let children = (1...5).map { i in
            FileNodeBuilder.file("file\(i).txt", size: Int64(i * 100))
        }
        let root = FileNodeBuilder.tree("root", children: children)

        let bounds = CGRect(x: 0, y: 0, width: 600, height: 400)
        let rects = SquarifiedTreemap.layout(node: root, bounds: bounds, maxDepth: 0, minSize: 1)

        let totalArea = rects.reduce(0.0) { $0 + Double($1.rect.width * $1.rect.height) }
        let boundsArea = Double(bounds.width * bounds.height)
        XCTAssertEqual(totalArea, boundsArea, accuracy: boundsArea * 0.01)
    }

    func testNoOverlaps() {
        let children = (1...4).map { i in
            FileNodeBuilder.file("file\(i).txt", size: Int64(i * 200))
        }
        let root = FileNodeBuilder.tree("root", children: children)

        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let rects = SquarifiedTreemap.layout(node: root, bounds: bounds, maxDepth: 0, minSize: 1)

        // Check pairwise for overlaps (allowing touching edges)
        for i in 0..<rects.count {
            for j in (i + 1)..<rects.count {
                let intersection = rects[i].rect.intersection(rects[j].rect)
                // Rects can touch (share an edge) but not have 2D overlap
                let overlapArea = intersection.isNull ? 0 : intersection.width * intersection.height
                XCTAssertLessThan(overlapArea, 1.0,
                    "Rects \(i) and \(j) overlap: \(rects[i].rect) vs \(rects[j].rect)")
            }
        }
    }

    func testMinSizeFilteringExcludesSmallRects() {
        let big = FileNodeBuilder.file("big.txt", size: 10000)
        let tiny = FileNodeBuilder.file("tiny.txt", size: 1)
        let root = FileNodeBuilder.tree("root", children: [big, tiny])

        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rects = SquarifiedTreemap.layout(node: root, bounds: bounds, maxDepth: 0, minSize: 20)

        // The tiny file should be filtered out due to minSize
        let tinyRects = rects.filter { $0.node.name == "tiny.txt" }
        XCTAssertTrue(tinyRects.isEmpty, "Tiny rect should be filtered by minSize")
    }

    func testMaxDepthLimitsRecursion() {
        let deepFile = FileNodeBuilder.file("deep.txt", size: 100, path: "/test/root/sub/deep.txt")
        let sub = FileNodeBuilder.dir("sub", path: "/test/root/sub", children: [deepFile])
        let root = FileNodeBuilder.tree("root", path: "/test/root", children: [sub])

        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)

        // maxDepth=0 should only lay out direct children (sub dir)
        let rectsDepth0 = SquarifiedTreemap.layout(node: root, bounds: bounds, maxDepth: 0, minSize: 1)
        let hasDeepFile0 = rectsDepth0.contains { $0.node.name == "deep.txt" }
        XCTAssertFalse(hasDeepFile0, "maxDepth=0 should not include nested files")

        // maxDepth=1 should lay out children of sub
        let rectsDepth1 = SquarifiedTreemap.layout(node: root, bounds: bounds, maxDepth: 1, minSize: 1)
        let hasDeepFile1 = rectsDepth1.contains { $0.node.name == "deep.txt" }
        XCTAssertTrue(hasDeepFile1, "maxDepth=1 should include nested files")
    }

    func testHiddenChildrenAreExcluded() {
        let visible = FileNodeBuilder.file("visible.txt", size: 500)
        let hidden = FileNodeBuilder.file("hidden.txt", size: 500)
        hidden.isHidden = true
        let root = FileNodeBuilder.dir("root", children: [visible, hidden])
        root.finalizeTree()
        // After finalize, root size includes hidden. We need recalculate.
        root.recalculateSizeUpward()

        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let rects = SquarifiedTreemap.layout(node: root, bounds: bounds, maxDepth: 0, minSize: 1)
        let names = rects.map(\.node.name)
        XCTAssertTrue(names.contains("visible.txt"))
        XCTAssertFalse(names.contains("hidden.txt"))
    }
}
