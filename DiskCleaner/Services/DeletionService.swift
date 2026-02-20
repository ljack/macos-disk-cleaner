import AppKit

/// Protocol for deletion services, enabling testability with mocks.
protocol DeletionServiceProtocol: Actor {
    func moveToTrash(urls: [URL]) async throws -> [URL]
    @discardableResult
    func moveToTrash(url: URL) async throws -> URL
}

/// Service for moving files to Trash via NSWorkspace (undoable deletion).
/// Uses NSWorkspace.recycle for Trash deletion. Under App Sandbox, the caller
/// must ensure sandbox access has been granted (via NSOpenPanel) for the paths.
actor DeletionService: DeletionServiceProtocol {
    /// Move URLs to Trash. Returns the new Trash URLs for each item.
    func moveToTrash(urls: [URL]) async throws -> [URL] {
        let newURLsByOriginal: [URL: URL] = try await withCheckedThrowingContinuation { continuation in
            NSWorkspace.shared.recycle(urls) { newURLs, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: newURLs)
                }
            }
        }
        // Return trash URLs in the same order as the input
        return urls.compactMap { newURLsByOriginal[$0] }
    }

    /// Move a single URL to Trash. Returns the Trash URL.
    @discardableResult
    func moveToTrash(url: URL) async throws -> URL {
        let results = try await moveToTrash(urls: [url])
        return results.first ?? url
    }

    /// Restore an item from Trash to its original location.
    func restoreFromTrash(trashURL: URL, to originalURL: URL) async throws {
        try await MainActor.run {
            let parent = originalURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: trashURL, to: originalURL)
        }
    }
}
