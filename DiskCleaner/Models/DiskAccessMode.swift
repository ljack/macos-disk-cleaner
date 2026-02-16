import Foundation

/// Retained for backward compatibility with persisted exclusion rules.
/// In the sandboxed App Store version, the scan root is always user-selected
/// via NSOpenPanel, so this enum is no longer used for scan root determination.
enum DiskAccessMode: String, CaseIterable, Codable {
    case userDirectory = "Home Directory"
    case fullDisk = "Full Disk"
}
