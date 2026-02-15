import Foundation

/// Progress update sent during scanning
struct ScanProgress: Sendable {
    let filesScanned: Int
    let directoriesScanned: Int
    let currentPath: String
    let bytesScanned: Int64
}

/// Actor that performs recursive filesystem scanning with progress reporting and cancellation.
actor ScanningEngine {
    private let fileManager = FileManager.default
    private let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .fileSizeKey,
        .totalFileAllocatedSizeKey,
        .nameKey
    ]

    private var filesScanned = 0
    private var directoriesScanned = 0
    private var bytesScanned: Int64 = 0
    private let progressInterval = 500

    /// Scan a directory tree and return the root FileNode.
    /// Reports progress via the callback (throttled to every 500 files).
    func scan(
        root: URL,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> FileNode {
        filesScanned = 0
        directoriesScanned = 0
        bytesScanned = 0

        let rootNode = try await scanDirectory(url: root, parent: nil, onProgress: onProgress)
        rootNode.finalizeTree()

        // Final progress report
        onProgress(ScanProgress(
            filesScanned: filesScanned,
            directoriesScanned: directoriesScanned,
            currentPath: root.path,
            bytesScanned: bytesScanned
        ))

        return rootNode
    }

    private func scanDirectory(
        url: URL,
        parent: FileNode?,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> FileNode {
        try Task.checkCancellation()

        let node = FileNode(url: url, name: url.lastPathComponent, isDirectory: true)
        node.parent = parent
        directoriesScanned += 1

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles]
            )
        } catch {
            // Permission denied — mark node and return empty
            node.isPermissionDenied = true
            return node
        }

        for itemURL in contents {
            try Task.checkCancellation()

            let resourceValues: URLResourceValues
            do {
                resourceValues = try itemURL.resourceValues(forKeys: resourceKeys)
            } catch {
                continue
            }

            // Skip symbolic links to prevent loops and double-counting
            if resourceValues.isSymbolicLink == true {
                continue
            }

            if resourceValues.isDirectory == true {
                let childNode = try await scanDirectory(
                    url: itemURL,
                    parent: node,
                    onProgress: onProgress
                )
                node.children.append(childNode)
            } else {
                let fileSize = Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)
                let fileNode = FileNode(
                    url: itemURL,
                    name: resourceValues.name ?? itemURL.lastPathComponent,
                    isDirectory: false,
                    size: fileSize
                )
                fileNode.parent = node
                node.children.append(fileNode)

                filesScanned += 1
                bytesScanned += fileSize

                // Throttled progress reporting
                if filesScanned % progressInterval == 0 {
                    let progress = ScanProgress(
                        filesScanned: filesScanned,
                        directoriesScanned: directoriesScanned,
                        currentPath: itemURL.path,
                        bytesScanned: bytesScanned
                    )
                    onProgress(progress)
                }
            }
        }

        return node
    }
}
