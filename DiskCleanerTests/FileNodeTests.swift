import XCTest
@testable import DiskCleaner

final class FileNodeTests: XCTestCase {

    // MARK: - finalizeTree

    func testFinalizeTreeRollsUpSizesAndSorts() {
        let child1 = FileNodeBuilder.file("small.txt", size: 100)
        let child2 = FileNodeBuilder.file("big.txt", size: 500)
        let child3 = FileNodeBuilder.file("medium.txt", size: 300)
        let root = FileNodeBuilder.tree("root", children: [child1, child2, child3])

        XCTAssertEqual(root.size, 900)
        // Children should be sorted by size descending
        XCTAssertEqual(root.children[0].name, "big.txt")
        XCTAssertEqual(root.children[1].name, "medium.txt")
        XCTAssertEqual(root.children[2].name, "small.txt")
    }

    func testFinalizeTreeCalculatesDescendantCount() {
        let subChild = FileNodeBuilder.file("deep.txt", size: 50)
        let subDir = FileNodeBuilder.dir("sub", children: [subChild])
        let file = FileNodeBuilder.file("top.txt", size: 100)
        let root = FileNodeBuilder.tree("root", children: [subDir, file])

        // root has 2 direct children; sub has 1
        XCTAssertEqual(root.descendantCount, 3) // sub + deep.txt + top.txt
        XCTAssertEqual(subDir.descendantCount, 1) // deep.txt
    }

    func testFinalizeTreeNestedDirectorySizeRollup() {
        let deepFile = FileNodeBuilder.file("deep.txt", size: 200)
        let innerDir = FileNodeBuilder.dir("inner", children: [deepFile])
        let topFile = FileNodeBuilder.file("top.txt", size: 100)
        let root = FileNodeBuilder.tree("root", children: [innerDir, topFile])

        XCTAssertEqual(innerDir.size, 200)
        XCTAssertEqual(root.size, 300)
    }

    // MARK: - recalculateSizeUpward

    func testRecalculateSizeUpwardExcludesTrashedAndHidden() {
        let file1 = FileNodeBuilder.file("a.txt", size: 100)
        let file2 = FileNodeBuilder.file("b.txt", size: 200)
        let file3 = FileNodeBuilder.file("c.txt", size: 300)
        let root = FileNodeBuilder.tree("root", children: [file1, file2, file3])

        XCTAssertEqual(root.size, 600)

        file2.isTrashed = true
        root.recalculateSizeUpward()
        XCTAssertEqual(root.size, 400)

        file3.isHidden = true
        root.recalculateSizeUpward()
        XCTAssertEqual(root.size, 100)
    }

    func testRecalculateSizeUpwardPropagates() {
        let file = FileNodeBuilder.file("f.txt", size: 500)
        let inner = FileNodeBuilder.dir("inner", children: [file])
        let root = FileNodeBuilder.tree("root", children: [inner])

        XCTAssertEqual(root.size, 500)

        file.isTrashed = true
        inner.recalculateSizeUpward()
        XCTAssertEqual(inner.size, 0)
        XCTAssertEqual(root.size, 0)
    }

    // MARK: - findNode(at:)

    func testFindNodeExactMatch() {
        let file = FileNodeBuilder.file("target.txt", size: 10, path: "/test/root/target.txt")
        let root = FileNodeBuilder.tree("root", path: "/test/root", children: [file])

        let found = root.findNode(at: URL(fileURLWithPath: "/test/root/target.txt"))
        XCTAssertEqual(found?.name, "target.txt")
    }

    func testFindNodeDescendantMatch() {
        let deep = FileNodeBuilder.file("deep.txt", size: 10, path: "/test/root/sub/deep.txt")
        let sub = FileNodeBuilder.dir("sub", path: "/test/root/sub", children: [deep])
        let root = FileNodeBuilder.tree("root", path: "/test/root", children: [sub])

        let found = root.findNode(at: URL(fileURLWithPath: "/test/root/sub/deep.txt"))
        XCTAssertEqual(found?.name, "deep.txt")
    }

    func testFindNodeMiss() {
        let file = FileNodeBuilder.file("exists.txt", size: 10, path: "/test/root/exists.txt")
        let root = FileNodeBuilder.tree("root", path: "/test/root", children: [file])

        let found = root.findNode(at: URL(fileURLWithPath: "/test/root/missing.txt"))
        XCTAssertNil(found)
    }

    func testFindNodeReturnsRootForExactRootMatch() {
        let root = FileNodeBuilder.tree("root", path: "/test/root", children: [])
        let found = root.findNode(at: URL(fileURLWithPath: "/test/root"))
        XCTAssertEqual(found?.name, "root")
    }

    // MARK: - markAsTrashed / unmarkTrashed

    func testMarkAsTrashedSetsFlags() {
        let file = FileNodeBuilder.file("f.txt", size: 100, path: "/test/root/f.txt")
        let root = FileNodeBuilder.tree("root", path: "/test/root", children: [file])

        let trashURL = URL(fileURLWithPath: "/.Trash/f.txt")
        file.markAsTrashed(trashURL: trashURL)

        XCTAssertTrue(file.isTrashed)
        XCTAssertEqual(file.trashURL, trashURL)
        // Parent size should be recalculated to exclude trashed child
        XCTAssertEqual(root.size, 0)
    }

    func testUnmarkTrashedClearsFlags() {
        let file = FileNodeBuilder.file("f.txt", size: 100, path: "/test/root/f.txt")
        let root = FileNodeBuilder.tree("root", path: "/test/root", children: [file])

        file.markAsTrashed(trashURL: URL(fileURLWithPath: "/.Trash/f.txt"))
        XCTAssertEqual(root.size, 0)

        file.unmarkTrashed()
        XCTAssertFalse(file.isTrashed)
        XCTAssertNil(file.trashURL)
        // Note: unmarkTrashed reads size from disk which won't work in test
        // but the flags should be cleared
    }

    // MARK: - removeChild

    func testRemoveChildRemovesAndRecalculates() {
        let file1 = FileNodeBuilder.file("a.txt", size: 100)
        let file2 = FileNodeBuilder.file("b.txt", size: 200)
        let root = FileNodeBuilder.tree("root", children: [file1, file2])

        XCTAssertEqual(root.size, 300)
        XCTAssertEqual(root.children.count, 2)

        root.removeChild(file1)
        XCTAssertEqual(root.children.count, 1)
        XCTAssertEqual(root.size, 200)
    }

    // MARK: - fractionOfParent

    func testFractionOfParentNormal() {
        let file1 = FileNodeBuilder.file("a.txt", size: 300)
        let file2 = FileNodeBuilder.file("b.txt", size: 700)
        let root = FileNodeBuilder.tree("root", children: [file1, file2])

        XCTAssertEqual(file1.fractionOfParent, 0.3, accuracy: 0.001)
        XCTAssertEqual(file2.fractionOfParent, 0.7, accuracy: 0.001)
        _ = root  // prevent weak parent from being deallocated
    }

    func testFractionOfParentRootNode() {
        let root = FileNodeBuilder.tree("root", children: [])
        XCTAssertEqual(root.fractionOfParent, 1.0)
    }

    func testFractionOfParentZeroSizeParent() {
        let file = FileNodeBuilder.file("empty.txt", size: 0)
        _ = FileNodeBuilder.tree("root", children: [file])
        // Parent size is 0, so fractionOfParent returns 1.0
        XCTAssertEqual(file.fractionOfParent, 1.0)
    }

    // MARK: - formattedSize

    func testFormattedSizeIsNonEmpty() {
        let file = FileNodeBuilder.file("test.txt", size: 1024 * 1024)
        XCTAssertFalse(file.formattedSize.isEmpty)
    }
}
