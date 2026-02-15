import Foundation

/// A record of an item moved to Trash by the app
struct TrashedItem: Identifiable, Codable {
    let id: UUID
    let originalURL: URL
    let trashURL: URL
    let name: String
    let size: Int64
    let date: Date
    let source: TrashSource

    enum TrashSource: String, Codable {
        case fileTree = "File Tree"
        case suggestion = "Suggestion"
        case appUninstall = "App Uninstall"
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Whether the item still exists in Trash
    var existsInTrash: Bool {
        FileManager.default.fileExists(atPath: trashURL.path)
    }
}
