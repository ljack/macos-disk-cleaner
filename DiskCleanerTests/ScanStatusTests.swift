import XCTest
@testable import DiskCleaner

final class ScanStatusTests: XCTestCase {

    func testReadyToScan() {
        let status = ScanStatus.readyToScan
        XCTAssertEqual(status.label, "Scan Now")
        XCTAssertEqual(status.icon, "play.circle.fill")
        XCTAssertTrue(status.canStartScan)
        XCTAssertFalse(status.canStopScan)
    }

    func testScanning() {
        let status = ScanStatus.scanning
        XCTAssertEqual(status.label, "Scanning...")
        XCTAssertEqual(status.icon, "progress.indicator")
        XCTAssertFalse(status.canStartScan)
        XCTAssertTrue(status.canStopScan)
    }

    func testComplete() {
        let status = ScanStatus.complete
        XCTAssertEqual(status.label, "Scan Complete")
        XCTAssertEqual(status.icon, "checkmark.circle.fill")
        XCTAssertTrue(status.canStartScan)
        XCTAssertFalse(status.canStopScan)
    }

    func testResultsAging() {
        let status = ScanStatus.resultsAging
        XCTAssertEqual(status.label, "Results Aging")
        XCTAssertEqual(status.icon, "clock.fill")
        XCTAssertTrue(status.canStartScan)
        XCTAssertFalse(status.canStopScan)
    }

    func testOutdated() {
        let status = ScanStatus.outdated
        XCTAssertEqual(status.label, "Rescan Needed")
        XCTAssertEqual(status.icon, "exclamationmark.triangle.fill")
        XCTAssertTrue(status.canStartScan)
        XCTAssertFalse(status.canStopScan)
    }

    func testStopped() {
        let status = ScanStatus.stopped
        XCTAssertEqual(status.label, "Scan Stopped")
        XCTAssertEqual(status.icon, "stop.circle.fill")
        XCTAssertTrue(status.canStartScan)
        XCTAssertFalse(status.canStopScan)
    }

    func testFailed() {
        let status = ScanStatus.failed("Something went wrong")
        XCTAssertEqual(status.label, "Scan Failed")
        XCTAssertEqual(status.icon, "xmark.circle.fill")
        XCTAssertTrue(status.canStartScan)
        XCTAssertFalse(status.canStopScan)
    }

    func testAllStatusesHaveNonEmptyLabelsAndIcons() {
        let statuses: [ScanStatus] = [
            .readyToScan, .scanning, .complete, .resultsAging,
            .outdated, .stopped, .failed("error")
        ]
        for status in statuses {
            XCTAssertFalse(status.label.isEmpty, "\(status) should have non-empty label")
            XCTAssertFalse(status.icon.isEmpty, "\(status) should have non-empty icon")
        }
    }
}
