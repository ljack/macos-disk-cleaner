import XCTest
import AppKit
@testable import DiskCleaner

@MainActor
final class AppUninstallerViewModelTests: XCTestCase {

    private var viewModel: AppUninstallerViewModel!
    private var mockDeletion: MockDeletionService!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = AppUninstallerViewModel()
        mockDeletion = MockDeletionService()
    }

    // MARK: - Helpers

    private func makeApp(name: String, bundleSize: Int64 = 1000, associatedFiles: [AssociatedFile] = []) -> InstalledApp {
        InstalledApp(
            name: name,
            bundleIdentifier: "com.test.\(name.lowercased())",
            bundleURL: URL(fileURLWithPath: "/Applications/\(name).app"),
            bundleSize: bundleSize,
            icon: NSImage(),
            associatedFiles: associatedFiles
        )
    }

    // MARK: - displayedApps filtering

    func testDisplayedAppsFiltersBySearchText() {
        viewModel.apps = [
            makeApp(name: "Safari"),
            makeApp(name: "Xcode"),
            makeApp(name: "Slack"),
        ]

        viewModel.searchText = "S"
        let names = viewModel.displayedApps.map(\.name)
        XCTAssertTrue(names.contains("Safari"))
        XCTAssertTrue(names.contains("Slack"))
        XCTAssertFalse(names.contains("Xcode"))
    }

    func testDisplayedAppsEmptySearchReturnsAll() {
        viewModel.apps = [makeApp(name: "A"), makeApp(name: "B")]
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.displayedApps.count, 2)
    }

    // MARK: - displayedApps sorting

    func testDisplayedAppsSortByTotalSize() {
        viewModel.apps = [
            makeApp(name: "Small", bundleSize: 100),
            makeApp(name: "Big", bundleSize: 9000),
            makeApp(name: "Medium", bundleSize: 3000),
        ]
        viewModel.sortOrder = .totalSize
        let names = viewModel.displayedApps.map(\.name)
        XCTAssertEqual(names, ["Big", "Medium", "Small"])
    }

    func testDisplayedAppsSortByName() {
        viewModel.apps = [
            makeApp(name: "Zeta"),
            makeApp(name: "Alpha"),
            makeApp(name: "Middle"),
        ]
        viewModel.sortOrder = .name
        let names = viewModel.displayedApps.map(\.name)
        XCTAssertEqual(names, ["Alpha", "Middle", "Zeta"])
    }

    func testDisplayedAppsSortByAppSize() {
        viewModel.apps = [
            makeApp(name: "A", bundleSize: 500),
            makeApp(name: "B", bundleSize: 2000),
        ]
        viewModel.sortOrder = .appSize
        let names = viewModel.displayedApps.map(\.name)
        XCTAssertEqual(names, ["B", "A"])
    }

    func testDisplayedAppsSortByDataSize() {
        let fileA = AssociatedFile(url: URL(fileURLWithPath: "/tmp/a"), size: 100, category: .caches)
        let fileB = AssociatedFile(url: URL(fileURLWithPath: "/tmp/b"), size: 5000, category: .caches)
        viewModel.apps = [
            makeApp(name: "LessData", bundleSize: 100, associatedFiles: [fileA]),
            makeApp(name: "MoreData", bundleSize: 100, associatedFiles: [fileB]),
        ]
        viewModel.sortOrder = .dataSize
        let names = viewModel.displayedApps.map(\.name)
        XCTAssertEqual(names, ["MoreData", "LessData"])
    }

    // MARK: - requestUninstall / cancelUninstall

    func testRequestUninstallSetsState() {
        let app = makeApp(name: "TestApp")
        viewModel.requestUninstall(app)

        XCTAssertEqual(viewModel.appToUninstall?.name, "TestApp")
        XCTAssertTrue(viewModel.showingUninstallConfirmation)
        XCTAssertNil(viewModel.uninstallError)
    }

    func testCancelUninstallClearsState() {
        let app = makeApp(name: "TestApp")
        viewModel.requestUninstall(app)
        viewModel.cancelUninstall()

        XCTAssertFalse(viewModel.showingUninstallConfirmation)
        XCTAssertNil(viewModel.appToUninstall)
        XCTAssertNil(viewModel.uninstallError)
    }

    // MARK: - performUninstall

    func testPerformUninstallSuccess() async throws {
        let app = makeApp(name: "ToDelete")
        viewModel.apps = [app, makeApp(name: "Keep")]
        viewModel.requestUninstall(app)

        let expectation = XCTestExpectation(description: "Uninstall completes")

        viewModel.performUninstall(using: mockDeletion) { _, _, uninstalledApp in
            XCTAssertEqual(uninstalledApp.name, "ToDelete")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2)

        XCTAssertEqual(viewModel.apps.count, 1)
        XCTAssertEqual(viewModel.apps.first?.name, "Keep")
        XCTAssertFalse(viewModel.showingUninstallConfirmation)
        XCTAssertNil(viewModel.appToUninstall)
        XCTAssertFalse(viewModel.isUninstalling)
    }

    func testPerformUninstallFailureSetsError() async throws {
        let app = makeApp(name: "FailApp")
        viewModel.apps = [app]
        viewModel.requestUninstall(app)

        // Configure mock to throw
        await mockDeletion.setShouldThrow(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sandbox denied"])
        )

        viewModel.performUninstall(using: mockDeletion)

        // Wait for async Task to complete
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertNotNil(viewModel.uninstallError)
        XCTAssertTrue(viewModel.uninstallError?.contains("Sandbox denied") ?? false,
            "Error should surface the deletion failure — this would catch the sandbox bug")
        XCTAssertFalse(viewModel.isUninstalling)
        // App should still be in the list since uninstall failed
        XCTAssertEqual(viewModel.apps.count, 1)
    }

    // MARK: - Sandbox access tests

    func testPerformUninstallRequestsAccessForAppParentDirectory() async throws {
        let app = makeApp(name: "TestApp")
        viewModel.apps = [app]
        viewModel.requestUninstall(app)

        let mockAccess = MockSandboxAccessProvider()
        let expectation = XCTestExpectation(description: "Uninstall completes")
        viewModel.performUninstall(using: mockDeletion, accessProvider: mockAccess) { _, _, _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)

        // Should have requested access to /Applications (parent of /Applications/TestApp.app)
        XCTAssertEqual(mockAccess.requestedURLs.count, 1)
        XCTAssertEqual(mockAccess.requestedURLs.first, app.bundleURL.deletingLastPathComponent())
    }

    func testPerformUninstallFailsWhenUserDeniesAccess() async throws {
        let app = makeApp(name: "DeniedApp")
        viewModel.apps = [app]
        viewModel.requestUninstall(app)

        let mockAccess = MockSandboxAccessProvider()
        mockAccess.grantAccess = false

        viewModel.performUninstall(using: mockDeletion, accessProvider: mockAccess)
        try await Task.sleep(for: .milliseconds(200))

        // Should set an error, not crash or silently fail
        XCTAssertNotNil(viewModel.uninstallError)
        // App should remain in the list
        XCTAssertEqual(viewModel.apps.count, 1)
        XCTAssertFalse(viewModel.isUninstalling)
    }

    func testPerformUninstallWithGrantedAccessCallsDeletionService() async throws {
        let app = makeApp(name: "GrantedApp")
        viewModel.apps = [app]
        viewModel.requestUninstall(app)

        let mockAccess = MockSandboxAccessProvider()
        mockAccess.grantAccess = true

        let expectation = XCTestExpectation(description: "Uninstall completes")
        viewModel.performUninstall(using: mockDeletion, accessProvider: mockAccess) { _, _, _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)

        // Deletion service should have been called with correct URLs
        let calls = await mockDeletion.moveToTrashURLsCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertTrue(calls.first!.contains(app.bundleURL))
    }

    // MARK: - Deletion service URL verification

    func testPerformUninstallCallsDeletionServiceWithCorrectURLs() async throws {
        let assocFile = AssociatedFile(url: URL(fileURLWithPath: "/tmp/pref.plist"), size: 100, category: .preferences)
        let app = makeApp(name: "TestApp", bundleSize: 5000, associatedFiles: [assocFile])
        viewModel.apps = [app]
        viewModel.requestUninstall(app)

        let expectation = XCTestExpectation(description: "Uninstall completes")
        viewModel.performUninstall(using: mockDeletion) { _, _, _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)

        let calls = await mockDeletion.moveToTrashURLsCalls
        XCTAssertEqual(calls.count, 1)
        let trashedURLs = calls.first!
        XCTAssertTrue(trashedURLs.contains(app.bundleURL))
        XCTAssertTrue(trashedURLs.contains(assocFile.url))
    }
}
