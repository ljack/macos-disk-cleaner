import XCTest
@testable import DiskCleaner

@MainActor
final class DiskSpaceHistoryTests: XCTestCase {

    private var history: DiskSpaceHistory!

    override func setUp() async throws {
        try await super.setUp()
        // Clear any persisted data to start fresh
        UserDefaults.standard.removeObject(forKey: "diskSpaceHistory")
        history = DiskSpaceHistory()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "diskSpaceHistory")
        super.tearDown()
    }

    func testRecordAppendsSnapshot() {
        history.record(freeBytes: 100_000_000)
        XCTAssertEqual(history.snapshots.count, 1)
        XCTAssertEqual(history.snapshots.first?.freeBytes, 100_000_000)
    }

    func testMultipleRecordsAccumulate() {
        history.record(freeBytes: 100_000_000)
        history.record(freeBytes: 200_000_000)
        history.record(freeBytes: 300_000_000)
        XCTAssertEqual(history.snapshots.count, 3)
    }

    func testSnapshotsAreSortedByDate() {
        history.record(freeBytes: 100)
        history.record(freeBytes: 200)
        history.record(freeBytes: 300)

        for i in 0..<(history.snapshots.count - 1) {
            XCTAssertLessThanOrEqual(
                history.snapshots[i].date,
                history.snapshots[i + 1].date,
                "Snapshots should be sorted by date ascending"
            )
        }
    }

    func testCompactionPreservesRecentPoints() {
        // Record several points "now" — all should be preserved (within 24h)
        for i in 0..<10 {
            history.record(freeBytes: Int64(i * 1_000_000))
        }

        // All should be preserved since they're all within 24h
        XCTAssertEqual(history.snapshots.count, 10)
    }

    func testEmptyHistory() {
        XCTAssertTrue(history.snapshots.isEmpty)
    }
}
