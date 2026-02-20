import XCTest
@testable import DiskCleaner

@MainActor
final class DirectoryExclusionStoreTests: XCTestCase {

    private var store: DirectoryExclusionStore!
    private let suiteName = "com.diskcleaner.tests.exclusion.\(UUID().uuidString)"

    override func setUp() async throws {
        try await super.setUp()
        // Clear any persisted exclusion rules to start fresh
        UserDefaults.standard.removeObject(forKey: "directoryExclusionRules")
        store = DirectoryExclusionStore()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "directoryExclusionRules")
        super.tearDown()
    }

    func testUpsertRuleAddsNewRule() {
        let url = URL(fileURLWithPath: "/Users/test/Developer")
        store.upsertRule(for: url, remainingScans: 3)

        XCTAssertEqual(store.rules.count, 1)
        XCTAssertEqual(store.rules.first?.remainingScans, 3)
    }

    func testUpsertRuleUpdatesExisting() {
        let url = URL(fileURLWithPath: "/Users/test/Developer")
        store.upsertRule(for: url, remainingScans: 3)
        store.upsertRule(for: url, remainingScans: 5)

        XCTAssertEqual(store.rules.count, 1)
        XCTAssertEqual(store.rules.first?.remainingScans, 5)
    }

    func testRemoveRule() {
        let url = URL(fileURLWithPath: "/Users/test/Developer")
        store.upsertRule(for: url, remainingScans: 3)
        let ruleID = store.rules.first!.id

        store.removeRule(id: ruleID)
        XCTAssertTrue(store.rules.isEmpty)
    }

    func testActiveScanRulesOnlyReturnsActiveRules() {
        let url1 = URL(fileURLWithPath: "/Users/test/Active")
        let url2 = URL(fileURLWithPath: "/Users/test/Inactive")
        store.upsertRule(for: url1, remainingScans: 3)
        store.upsertRule(for: url2, remainingScans: 0)

        let activeRules = store.activeScanRules()
        XCTAssertEqual(activeRules.count, 1)
        XCTAssertEqual(activeRules.first?.normalizedPath, url1.standardizedFileURL.path)
    }

    func testConsumeMatchedRulesDecrementsCounters() {
        let url = URL(fileURLWithPath: "/Users/test/Dir")
        store.upsertRule(for: url, remainingScans: 3)
        let ruleID = store.rules.first!.id

        store.consumeMatchedRules(Set([ruleID]))

        XCTAssertEqual(store.rules.first?.remainingScans, 2)
        XCTAssertEqual(store.rules.first?.totalMatches, 1)
        XCTAssertNotNil(store.rules.first?.lastMatchedAt)
    }

    func testConsumeMatchedRulesDoesNotGoNegative() {
        let url = URL(fileURLWithPath: "/Users/test/Dir")
        store.upsertRule(for: url, remainingScans: 1)
        let ruleID = store.rules.first!.id

        store.consumeMatchedRules(Set([ruleID]))
        XCTAssertEqual(store.rules.first?.remainingScans, 0)

        // Consuming again should not go negative
        store.consumeMatchedRules(Set([ruleID]))
        XCTAssertEqual(store.rules.first?.remainingScans, 0)
    }

    func testActiveRuleCount() {
        let url1 = URL(fileURLWithPath: "/Users/test/A")
        let url2 = URL(fileURLWithPath: "/Users/test/B")
        let url3 = URL(fileURLWithPath: "/Users/test/C")
        store.upsertRule(for: url1, remainingScans: 3)
        store.upsertRule(for: url2, remainingScans: 0)
        store.upsertRule(for: url3, remainingScans: 1)

        XCTAssertEqual(store.activeRuleCount, 2)
    }

    func testSetRemainingScansClamps() {
        let url = URL(fileURLWithPath: "/Users/test/Dir")
        store.upsertRule(for: url, remainingScans: 5)
        let ruleID = store.rules.first!.id

        store.setRemainingScans(for: ruleID, to: -10)
        XCTAssertEqual(store.rules.first?.remainingScans, 0)
    }

    func testSetRemainingScansUpdatesValue() {
        let url = URL(fileURLWithPath: "/Users/test/Dir")
        store.upsertRule(for: url, remainingScans: 5)
        let ruleID = store.rules.first!.id

        store.setRemainingScans(for: ruleID, to: 10)
        XCTAssertEqual(store.rules.first?.remainingScans, 10)
    }

    func testConsumeMatchedRulesWithEmptySetDoesNothing() {
        let url = URL(fileURLWithPath: "/Users/test/Dir")
        store.upsertRule(for: url, remainingScans: 5)

        store.consumeMatchedRules(Set())
        XCTAssertEqual(store.rules.first?.remainingScans, 5)
    }
}
