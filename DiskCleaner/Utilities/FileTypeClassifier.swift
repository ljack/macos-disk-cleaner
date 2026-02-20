import SwiftUI

/// File type categories for treemap coloring
enum FileTypeCategory: String, CaseIterable {
    case code = "Code"
    case media = "Media"
    case documents = "Documents"
    case archives = "Archives"
    case system = "System"
    case data = "Data"
    case directory = "Directory"
    case other = "Other"

    var color: Color {
        switch self {
        case .code:       return Color(red: 0.25, green: 0.47, blue: 0.85)
        case .media:      return Color(red: 0.30, green: 0.69, blue: 0.31)
        case .documents:  return Color(red: 0.93, green: 0.60, blue: 0.15)
        case .archives:   return Color(red: 0.61, green: 0.32, blue: 0.84)
        case .system:     return Color(red: 0.55, green: 0.55, blue: 0.58)
        case .data:       return Color(red: 0.15, green: 0.70, blue: 0.75)
        case .directory:  return Color(red: 0.48, green: 0.53, blue: 0.62)
        case .other:      return Color(red: 0.65, green: 0.60, blue: 0.55)
        }
    }

    var icon: String {
        switch self {
        case .code:       return "chevron.left.forwardslash.chevron.right"
        case .media:      return "photo"
        case .documents:  return "doc"
        case .archives:   return "archivebox"
        case .system:     return "gearshape"
        case .data:       return "cylinder"
        case .directory:  return "folder"
        case .other:      return "doc.questionmark"
        }
    }
}

/// Maps file extensions to categories for treemap coloring
enum FileTypeClassifier {
    private static let codeExtensions: Set<String> = [
        "swift", "m", "h", "c", "cpp", "cc", "java", "kt", "py", "rb", "rs",
        "go", "js", "jsx", "ts", "tsx", "html", "css", "scss", "sass", "less",
        "vue", "svelte", "php", "pl", "sh", "bash", "zsh", "fish",
        "r", "scala", "clj", "hs", "ml", "ex", "exs", "erl",
        "toml", "yaml", "yml", "json", "xml", "plist", "xcconfig",
        "pbxproj", "storyboard", "xib", "entitlements",
        "makefile", "cmake", "gradle", "podspec", "gemspec",
    ]

    private static let mediaExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "webp", "heic", "heif",
        "svg", "ico", "icns", "pdf",
        "mp3", "wav", "aac", "flac", "ogg", "m4a", "wma", "aiff",
        "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "3gp",
        "psd", "ai", "sketch", "fig", "xd",
    ]

    private static let documentExtensions: Set<String> = [
        "doc", "docx", "txt", "rtf", "odt", "pages",
        "xls", "xlsx", "csv", "ods", "numbers",
        "ppt", "pptx", "odp", "keynote",
        "md", "rst", "tex", "org",
    ]

    private static let archiveExtensions: Set<String> = [
        "zip", "tar", "gz", "bz2", "xz", "7z", "rar",
        "dmg", "iso", "pkg", "deb", "rpm",
        "jar", "war", "ear",
    ]

    private static let systemExtensions: Set<String> = [
        "dylib", "so", "a", "o", "framework",
        "app", "kext", "plugin", "bundle",
        "log", "crash",
    ]

    private static let dataExtensions: Set<String> = [
        "db", "sqlite", "sqlite3", "realm",
        "core", "dat", "bin",
    ]

    static func classify(url: URL) -> FileTypeCategory {
        let ext = url.pathExtension.lowercased()
        if ext.isEmpty { return .other }

        if codeExtensions.contains(ext) { return .code }
        if mediaExtensions.contains(ext) { return .media }
        if documentExtensions.contains(ext) { return .documents }
        if archiveExtensions.contains(ext) { return .archives }
        if systemExtensions.contains(ext) { return .system }
        if dataExtensions.contains(ext) { return .data }

        return .other
    }
}
