import XCTest
@testable import DiskCleaner

final class ExcludedDirectoryRuleTests: XCTestCase {

    func testIsActiveWhenRemainingScansGreaterThanZero() {
        let rule = ExcludedDirectoryRule(path: "/test/path", remainingScans: 3)
        XCTAssertTrue(rule.isActive)
    }

    func testIsInactiveWhenRemainingScansIsZero() {
        let rule = ExcludedDirectoryRule(path: "/test/path", remainingScans: 0)
        XCTAssertFalse(rule.isActive)
    }

    func testRemainingScansClampedToZero() {
        let rule = ExcludedDirectoryRule(path: "/test/path", remainingScans: -5)
        XCTAssertEqual(rule.remainingScans, 0)
        XCTAssertFalse(rule.isActive)
    }

    func testNormalizedPathResolvesCorrectly() {
        let rule = ExcludedDirectoryRule(path: "/Users/test/Documents/../Downloads", remainingScans: 1)
        let expected = URL(fileURLWithPath: "/Users/test/Documents/../Downloads").standardizedFileURL.path
        XCTAssertEqual(rule.normalizedPath, expected)
    }

    func testDefaultScopeIsAllModes() {
        let rule = ExcludedDirectoryRule(path: "/test", remainingScans: 1)
        XCTAssertEqual(rule.scope, .allModes)
    }

    func testIdentity() {
        let rule1 = ExcludedDirectoryRule(path: "/test/a", remainingScans: 1)
        let rule2 = ExcludedDirectoryRule(path: "/test/b", remainingScans: 1)
        XCTAssertNotEqual(rule1.id, rule2.id)
    }
}
