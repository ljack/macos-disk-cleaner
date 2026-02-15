import AppKit

/// Service for moving files to Trash via NSWorkspace (undoable deletion).
actor DeletionService {
    /// Move URLs to Trash. Returns the new Trash URLs for each item.
    func moveToTrash(urls: [URL]) async throws -> [URL] {
        // NSWorkspace.recycle is main-actor bound, so call on main
        try await MainActor.run {
            var trashedURLs: [URL] = []
            for url in urls {
                var resultURL: NSURL?
                try NSWorkspace.shared.recycle([url], completionHandler: { trashedItems, error in
                    // This is synchronous in practice for small batches
                })
                // Use the synchronous approach
                try FileManager.default.trashItem(at: url, resultingItemURL: &resultURL)
                if let trashed = resultURL as URL? {
                    trashedURLs.append(trashed)
                }
            }
            return trashedURLs
        }
    }

    /// Move a single URL to Trash. Returns the Trash URL.
    @discardableResult
    func moveToTrash(url: URL) async throws -> URL {
        try await MainActor.run {
            var resultURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultURL)
            return (resultURL as URL?) ?? url
        }
    }

    /// Restore an item from Trash to its original location.
    func restoreFromTrash(trashURL: URL, to originalURL: URL) async throws {
        try await MainActor.run {
            // Ensure parent directory exists
            let parent = originalURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: trashURL, to: originalURL)
        }
    }
}
