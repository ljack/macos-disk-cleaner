import Foundation

/// Categories of known space wasters
enum SpaceWasterCategory: String, CaseIterable, Identifiable {
    case xcodeDerivedData = "Xcode Derived Data"
    case xcodeArchives = "Xcode Archives"
    case xcodeDeviceSupport = "Xcode Device Support"
    case nodeModules = "node_modules"
    case userCaches = "User Caches"
    case dotCache = ".cache"
    case logs = "Logs"
    case homebrewCache = "Homebrew Cache"
    case dockerData = "Docker Data"
    case trash = "Trash"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .xcodeDerivedData, .xcodeArchives, .xcodeDeviceSupport: return "hammer"
        case .nodeModules: return "shippingbox"
        case .userCaches, .dotCache, .homebrewCache: return "archivebox"
        case .logs: return "doc.text"
        case .dockerData: return "cube"
        case .trash: return "trash"
        }
    }

    /// How risky is it to delete this?
    var riskLevel: RiskLevel {
        switch self {
        case .xcodeDerivedData, .xcodeDeviceSupport, .nodeModules,
             .userCaches, .dotCache, .logs, .homebrewCache, .trash:
            return .safe
        case .xcodeArchives, .dockerData:
            return .moderate
        }
    }

    var description: String {
        switch self {
        case .xcodeDerivedData: return "Build artifacts that Xcode regenerates automatically"
        case .xcodeArchives: return "Archived builds for App Store submissions"
        case .xcodeDeviceSupport: return "Debug symbols for connected iOS devices"
        case .nodeModules: return "npm/yarn dependencies (re-install with npm install)"
        case .userCaches: return "Application caches that will be recreated"
        case .dotCache: return "CLI tool caches"
        case .logs: return "Application log files"
        case .homebrewCache: return "Downloaded Homebrew package files"
        case .dockerData: return "Docker images, containers, and volumes"
        case .trash: return "Files already in Trash"
        }
    }
}

enum RiskLevel: String {
    case safe = "Safe"
    case moderate = "Moderate"

    var color: String {
        switch self {
        case .safe: return "green"
        case .moderate: return "orange"
        }
    }
}

/// A detected space waster with its location and size
struct SpaceWaster: Identifiable {
    let id = UUID()
    let category: SpaceWasterCategory
    let url: URL
    let size: Int64
    let itemCount: Int

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
