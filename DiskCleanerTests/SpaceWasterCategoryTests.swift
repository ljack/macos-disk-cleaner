import XCTest
@testable import DiskCleaner

final class SpaceWasterCategoryTests: XCTestCase {

    func testEachCategoryHasCorrectRiskLevel() {
        // Safe categories
        let safeCategories: [SpaceWasterCategory] = [
            .xcodeDerivedData, .xcodeDeviceSupport, .nodeModules,
            .userCaches, .dotCache, .logs, .homebrewCache, .trash
        ]
        for category in safeCategories {
            XCTAssertEqual(category.riskLevel, .safe, "\(category) should be safe")
        }

        // Moderate categories
        let moderateCategories: [SpaceWasterCategory] = [
            .xcodeArchives, .dockerData
        ]
        for category in moderateCategories {
            XCTAssertEqual(category.riskLevel, .moderate, "\(category) should be moderate")
        }
    }

    func testDescriptionNonEmptyForAllCases() {
        for category in SpaceWasterCategory.allCases {
            XCTAssertFalse(category.description.isEmpty, "\(category) should have a non-empty description")
        }
    }

    func testIconNonEmptyForAllCases() {
        for category in SpaceWasterCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have a non-empty icon")
        }
    }

    func testAllCasesAccountedFor() {
        // Verify we have all the expected cases
        XCTAssertEqual(SpaceWasterCategory.allCases.count, 10)
    }

    func testRiskLevelHasColorAndRawValue() {
        XCTAssertEqual(RiskLevel.safe.rawValue, "Safe")
        XCTAssertEqual(RiskLevel.safe.color, "green")
        XCTAssertEqual(RiskLevel.moderate.rawValue, "Moderate")
        XCTAssertEqual(RiskLevel.moderate.color, "orange")
    }
}
