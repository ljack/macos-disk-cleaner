import Foundation
@testable import DiskCleaner

@MainActor
final class MockSandboxAccessProvider: SandboxAccessProvider {
    var grantAccess = true
    var requestedURLs: [URL] = []

    func requestAccess(for url: URL) -> URL? {
        requestedURLs.append(url)
        return grantAccess ? url : nil
    }
}
