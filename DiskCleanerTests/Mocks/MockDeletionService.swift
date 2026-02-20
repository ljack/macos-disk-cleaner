import Foundation
@testable import DiskCleaner

/// Mock deletion service for testing ViewModels that depend on DeletionServiceProtocol.
actor MockDeletionService: DeletionServiceProtocol {
    var shouldThrow: Error?

    /// Record of calls for verification
    var moveToTrashURLsCalls: [[URL]] = []
    var moveToTrashSingleCalls: [URL] = []

    func setShouldThrow(_ error: Error?) {
        self.shouldThrow = error
    }

    func moveToTrash(urls: [URL]) async throws -> [URL] {
        moveToTrashURLsCalls.append(urls)
        if let error = shouldThrow {
            throw error
        }
        // Default: return trash URLs based on input
        return urls.map { URL(fileURLWithPath: "/.Trash/\($0.lastPathComponent)") }
    }

    @discardableResult
    func moveToTrash(url: URL) async throws -> URL {
        moveToTrashSingleCalls.append(url)
        if let error = shouldThrow {
            throw error
        }
        return URL(fileURLWithPath: "/.Trash/\(url.lastPathComponent)")
    }
}
