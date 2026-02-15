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

    /// Known TCC-protected directory names (direct children of ~)
    private static let tccProtectedNames: Set<String> = ["Desktop", "Documents", "Downloads"]

    private var homeURL: URL?
    private var pendingDirectories: [FileNode] = []
    private var exclusionRulesByPath: [String: UUID] = [:]
    private var matchedExclusionRuleIDs: Set<UUID> = []

    /// Check if a URL is a TCC-protected directory (direct child of home).
    /// Uses path comparison to avoid URL canonicalization mismatches.
    private func isTCCProtected(url: URL) -> Bool {
        guard let homeURL else { return false }
        return url.deletingLastPathComponent().path == homeURL.path
            && Self.tccProtectedNames.contains(url.lastPathComponent)
    }

    /// Scan a directory tree and return the root FileNode plus any TCC-skipped directories.
    /// Reports progress via the callback (throttled to every 500 files).
    func scan(
        root: URL,
        homeURL: URL,
        exclusionRules: [ScanExclusionRule],
        onProgress: @MainActor @escaping (ScanProgress) -> Void
    ) async throws -> (
        root: FileNode,
        pendingDirectories: [FileNode],
        matchedExclusionRuleIDs: Set<UUID>
    ) {
        filesScanned = 0
        directoriesScanned = 0
        bytesScanned = 0
        self.homeURL = homeURL
        pendingDirectories = []
        exclusionRulesByPath = Dictionary(uniqueKeysWithValues: exclusionRules.map { ($0.normalizedPath, $0.id) })
        matchedExclusionRuleIDs = []

        let rootNode = try await scanDirectory(url: root, parent: nil, skipTCC: true, onProgress: onProgress)
        rootNode.finalizeTree()

        // Final progress report
        await onProgress(ScanProgress(
            filesScanned: filesScanned,
            directoriesScanned: directoriesScanned,
            currentPath: root.path,
            bytesScanned: bytesScanned
        ))

        return (
            root: rootNode,
            pendingDirectories: pendingDirectories,
            matchedExclusionRuleIDs: matchedExclusionRuleIDs
        )
    }

    /// Scan a single directory subtree (used after user grants TCC permission).
    /// Does NOT apply TCC skip logic since the user has already granted access.
    func scanSubtree(
        at url: URL,
        onProgress: @MainActor @escaping (ScanProgress) -> Void
    ) async throws -> FileNode {
        filesScanned = 0
        directoriesScanned = 0
        bytesScanned = 0
        exclusionRulesByPath = [:]
        matchedExclusionRuleIDs = []

        let node = try await scanDirectory(url: url, parent: nil, skipTCC: false, onProgress: onProgress)
        node.finalizeTree()
        return node
    }

    private func scanDirectory(
        url: URL,
        parent: FileNode?,
        skipTCC: Bool,
        onProgress: @MainActor @escaping (ScanProgress) -> Void
    ) async throws -> FileNode {
        try Task.checkCancellation()

        let node = FileNode(url: url, name: url.lastPathComponent, isDirectory: true)
        node.parent = parent
        directoriesScanned += 1

        if let matchedRuleID = exclusionRulesByPath[url.standardizedFileURL.path] {
            node.excludedByRuleID = matchedRuleID
            matchedExclusionRuleIDs.insert(matchedRuleID)
            return node
        }

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

            // Intercept TCC-protected directories before touching them at all
            // (resourceValues or contentsOfDirectory could trigger TCC popups)
            if skipTCC && isTCCProtected(url: itemURL) {
                let childNode = FileNode(url: itemURL, name: itemURL.lastPathComponent, isDirectory: true)
                childNode.parent = node
                childNode.awaitingPermission = true
                pendingDirectories.append(childNode)
                node.children.append(childNode)
                directoriesScanned += 1
                continue
            }

            if let matchedRuleID = exclusionRulesByPath[itemURL.standardizedFileURL.path] {
                let childNode = FileNode(url: itemURL, name: itemURL.lastPathComponent, isDirectory: true)
                childNode.parent = node
                childNode.excludedByRuleID = matchedRuleID
                matchedExclusionRuleIDs.insert(matchedRuleID)
                node.children.append(childNode)
                directoriesScanned += 1
                continue
            }

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
                    skipTCC: skipTCC,
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
                    await onProgress(progress)
                }
            }
        }

        return node
    }
}
