import AppKit

/// Categories of files associated with an application
enum AssociatedFileCategory: String, CaseIterable {
    case applicationSupport = "Application Support"
    case caches = "Caches"
    case preferences = "Preferences"
    case savedState = "Saved State"
    case logs = "Logs"
    case containers = "Containers"
    case httpStorages = "HTTP Storages"
    case webKit = "WebKit"

    var icon: String {
        switch self {
        case .applicationSupport: return "folder.badge.gearshape"
        case .caches: return "archivebox"
        case .preferences: return "slider.horizontal.3"
        case .savedState: return "clock.arrow.circlepath"
        case .logs: return "doc.text"
        case .containers: return "shippingbox"
        case .httpStorages: return "network"
        case .webKit: return "globe"
        }
    }
}

/// A file or directory associated with an installed application
struct AssociatedFile: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    let category: AssociatedFileCategory

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// An installed macOS application with its bundle and associated data
struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String?
    let bundleURL: URL
    let bundleSize: Int64
    let icon: NSImage
    var associatedFiles: [AssociatedFile] = []

    var associatedSize: Int64 {
        associatedFiles.reduce(0) { $0 + $1.size }
    }

    var totalSize: Int64 {
        bundleSize + associatedSize
    }

    var formattedBundleSize: String {
        ByteCountFormatter.string(fromByteCount: bundleSize, countStyle: .file)
    }

    var formattedAssociatedSize: String {
        ByteCountFormatter.string(fromByteCount: associatedSize, countStyle: .file)
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
