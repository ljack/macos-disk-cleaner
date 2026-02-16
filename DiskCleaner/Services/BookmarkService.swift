import Foundation

/// Manages security-scoped bookmarks for sandboxed file access.
/// Persists bookmarks to UserDefaults so folder access survives app relaunch.
@MainActor
@Observable
final class BookmarkService {
    private static let bookmarksKey = "savedSecurityScopedBookmarks"

    /// Currently active security-scoped URL (access has been started)
    private(set) var activeURL: URL?

    /// All saved bookmark entries (name + bookmark data)
    private(set) var savedLocations: [SavedLocation] = []

    struct SavedLocation: Identifiable, Codable {
        let id: UUID
        let name: String
        let path: String
        let bookmarkData: Data
        var lastUsed: Date
    }

    init() {
        loadBookmarks()
    }

    // MARK: - Public API

    /// Save a security-scoped bookmark for a URL obtained from NSOpenPanel.
    /// Returns the resolved URL with active security scope.
    @discardableResult
    func saveBookmark(for url: URL) -> URL? {
        guard let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            return nil
        }

        let location = SavedLocation(
            id: UUID(),
            name: url.lastPathComponent,
            path: url.path,
            bookmarkData: bookmarkData,
            lastUsed: Date()
        )

        // Replace existing bookmark for same path
        savedLocations.removeAll { $0.path == url.path }
        savedLocations.insert(location, at: 0)
        persistBookmarks()

        return activateURL(url)
    }

    /// Restore and activate a saved bookmark by path.
    func restoreBookmark(for location: SavedLocation) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: location.bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale {
            // Re-save with fresh bookmark data
            if let freshData = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
                    savedLocations[index] = SavedLocation(
                        id: location.id,
                        name: location.name,
                        path: url.path,
                        bookmarkData: freshData,
                        lastUsed: Date()
                    )
                    persistBookmarks()
                }
            }
        } else {
            // Update last used date
            if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
                savedLocations[index] = SavedLocation(
                    id: location.id,
                    name: location.name,
                    path: location.path,
                    bookmarkData: location.bookmarkData,
                    lastUsed: Date()
                )
                persistBookmarks()
            }
        }

        return activateURL(url)
    }

    /// Restore the most recently used bookmark automatically on launch.
    func restoreMostRecent() -> URL? {
        guard let mostRecent = savedLocations.first else { return nil }
        return restoreBookmark(for: mostRecent)
    }

    /// Deactivate the currently active security-scoped URL.
    func deactivate() {
        if let url = activeURL {
            url.stopAccessingSecurityScopedResource()
            activeURL = nil
        }
    }

    /// Remove a saved location.
    func removeLocation(_ location: SavedLocation) {
        if activeURL?.path == location.path {
            deactivate()
        }
        savedLocations.removeAll { $0.id == location.id }
        persistBookmarks()
    }

    // MARK: - Private

    private func activateURL(_ url: URL) -> URL {
        // Stop previous access if any
        if let previous = activeURL, previous.path != url.path {
            previous.stopAccessingSecurityScopedResource()
        }

        if activeURL?.path != url.path {
            _ = url.startAccessingSecurityScopedResource()
        }
        activeURL = url
        return url
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarksKey),
              let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            return
        }
        savedLocations = locations
    }

    private func persistBookmarks() {
        guard let data = try? JSONEncoder().encode(savedLocations) else { return }
        UserDefaults.standard.set(data, forKey: Self.bookmarksKey)
    }
}
