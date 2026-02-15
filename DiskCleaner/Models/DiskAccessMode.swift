import Foundation

/// Whether scanning covers just the user directory or the full disk
enum DiskAccessMode: String, CaseIterable {
    case userDirectory = "Home Directory"
    case fullDisk = "Full Disk"

    var rootURL: URL {
        switch self {
        case .userDirectory:
            return FileManager.default.homeDirectoryForCurrentUser
        case .fullDisk:
            return URL(fileURLWithPath: "/")
        }
    }

    var icon: String {
        switch self {
        case .userDirectory: return "house"
        case .fullDisk: return "internaldrive"
        }
    }
}
