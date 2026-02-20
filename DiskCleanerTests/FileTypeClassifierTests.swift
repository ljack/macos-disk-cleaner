import XCTest
@testable import DiskCleaner

final class FileTypeClassifierTests: XCTestCase {

    func testCodeExtensions() {
        let codeExts = ["swift", "js", "py", "ts", "html", "css", "json", "yaml", "rs", "go"]
        for ext in codeExts {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            XCTAssertEqual(
                FileTypeClassifier.classify(url: url), .code,
                "Expected .\(ext) to classify as .code"
            )
        }
    }

    func testMediaExtensions() {
        let mediaExts = ["jpg", "jpeg", "png", "mp4", "mp3", "mov", "gif", "svg", "wav"]
        for ext in mediaExts {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            XCTAssertEqual(
                FileTypeClassifier.classify(url: url), .media,
                "Expected .\(ext) to classify as .media"
            )
        }
    }

    func testDocumentExtensions() {
        let docExts = ["doc", "docx", "txt", "pdf", "csv", "md", "xls"]
        for ext in docExts {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            // pdf is classified as media in the classifier
            let expected: FileTypeCategory = (ext == "pdf") ? .media : .documents
            XCTAssertEqual(
                FileTypeClassifier.classify(url: url), expected,
                "Expected .\(ext) to classify as \(expected)"
            )
        }
    }

    func testArchiveExtensions() {
        let archiveExts = ["zip", "tar", "gz", "dmg", "7z", "rar"]
        for ext in archiveExts {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            XCTAssertEqual(
                FileTypeClassifier.classify(url: url), .archives,
                "Expected .\(ext) to classify as .archives"
            )
        }
    }

    func testSystemExtensions() {
        let sysExts = ["dylib", "so", "app", "log", "crash"]
        for ext in sysExts {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            XCTAssertEqual(
                FileTypeClassifier.classify(url: url), .system,
                "Expected .\(ext) to classify as .system"
            )
        }
    }

    func testDataExtensions() {
        let dataExts = ["db", "sqlite", "sqlite3", "realm"]
        for ext in dataExts {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            XCTAssertEqual(
                FileTypeClassifier.classify(url: url), .data,
                "Expected .\(ext) to classify as .data"
            )
        }
    }

    func testUnknownExtensionReturnsOther() {
        let url = URL(fileURLWithPath: "/test/file.xyz123")
        XCTAssertEqual(FileTypeClassifier.classify(url: url), .other)
    }

    func testEmptyExtensionReturnsOther() {
        let url = URL(fileURLWithPath: "/test/Makefile")
        XCTAssertEqual(FileTypeClassifier.classify(url: url), .other)
    }

    func testCaseInsensitivity() {
        // URL pathExtension lowercases automatically, but let's verify
        let url = URL(fileURLWithPath: "/test/file.SWIFT")
        // pathExtension returns "SWIFT" but classifier lowercases
        XCTAssertEqual(FileTypeClassifier.classify(url: url), .code)
    }
}
