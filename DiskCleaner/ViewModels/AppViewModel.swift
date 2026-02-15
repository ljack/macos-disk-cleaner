import AppKit
import Foundation

/// View mode toggle
enum ViewMode: String, CaseIterable {
    case list = "List"
    case treemap = "Treemap"

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .treemap: return "square.grid.2x2"
        }
    }
}

/// Sidebar navigation items
enum SidebarItem: Hashable {
    case disk
    case permissions
    case apps
    case hiddenItems
    case history
    case suggestion(SpaceWasterCategory)
}

/// Central coordinator ViewModel
@MainActor
@Observable
final class AppViewModel {
    let scanVM = ScanViewModel()
    let suggestionsVM = SuggestionsViewModel()
    let uninstallerVM = AppUninstallerViewModel()
    let deletionService = DeletionService()
    let diskSpaceHistory = DiskSpaceHistory()

    var accessMode: DiskAccessMode = .userDirectory
    var viewMode: ViewMode = .list
    var selectedSidebarItem: SidebarItem? = .disk
    var hasFullDiskAccess: Bool = false

    // Auto-scan settings (persisted via UserDefaults)
    var autoScanEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "autoScanEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "autoScanEnabled") }
    }

    var autoScanDelay: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: "autoScanDelay")
            return value > 0 ? value : 3
        }
        set { UserDefaults.standard.set(max(0, newValue), forKey: "autoScanDelay") }
    }

    // Hidden nodes
    var hiddenNodes: [FileNode] = []
    var hasHiddenNodes: Bool { !hiddenNodes.isEmpty }

    // Trash history
    var trashHistory: [TrashedItem] = []

    // Selection for deletion
    var selectedNodes: Set<FileNode> = []

    // Disk space history popover
    var showingDiskSpaceHistory = false

    // Deletion confirmation
    var showingDeleteConfirmation = false
    var isDeleting = false
    var deletionError: String?

    // Treemap navigation
    var treemapRoot: FileNode?

    /// The node currently displayed (treemap zoom or scan root)
    var displayedRoot: FileNode? {
        treemapRoot ?? scanVM.rootNode
    }

    init() {
        hasFullDiskAccess = PermissionService.hasFullDiskAccess()
        loadTrashHistory()
        refreshDiskSpace()
    }

    private func loadTrashHistory() {
        guard let data = UserDefaults.standard.data(forKey: "trashHistory"),
              let items = try? JSONDecoder().decode([TrashedItem].self, from: data) else { return }
        trashHistory = items
    }

    private func saveTrashHistory() {
        guard let data = try? JSONEncoder().encode(trashHistory) else { return }
        UserDefaults.standard.set(data, forKey: "trashHistory")
    }

    func recordTrashed(originalURL: URL, trashURL: URL, size: Int64, source: TrashedItem.TrashSource) {
        let item = TrashedItem(
            id: UUID(),
            originalURL: originalURL,
            trashURL: trashURL,
            name: originalURL.lastPathComponent,
            size: size,
            date: Date(),
            source: source
        )
        trashHistory.insert(item, at: 0)
        // Keep last 200 entries
        if trashHistory.count > 200 {
            trashHistory = Array(trashHistory.prefix(200))
        }
        saveTrashHistory()
    }

    func restoreFromTrash(_ item: TrashedItem) {
        Task {
            do {
                try await deletionService.restoreFromTrash(trashURL: item.trashURL, to: item.originalURL)
                await MainActor.run {
                    self.trashHistory.removeAll { $0.id == item.id }
                    self.saveTrashHistory()
                    // Unmark the corresponding tree node if it exists
                    if let root = self.scanVM.rootNode,
                       let node = root.findNode(at: item.originalURL) {
                        node.unmarkTrashed()
                    }
                    self.suggestionsVM.detect(scanRoot: self.scanVM.rootNode)
                    self.refreshDiskSpace()
                }
            } catch {
                await MainActor.run {
                    self.deletionError = error.localizedDescription
                }
            }
        }
    }

    func restoreNodeFromTrash(_ node: FileNode) {
        guard let trashURL = node.trashURL else { return }
        Task {
            do {
                try await deletionService.restoreFromTrash(trashURL: trashURL, to: node.url)
                await MainActor.run {
                    node.unmarkTrashed()
                    self.trashHistory.removeAll { $0.originalURL == node.url }
                    self.saveTrashHistory()
                    self.suggestionsVM.detect(scanRoot: self.scanVM.rootNode)
                    self.refreshDiskSpace()
                }
            } catch {
                await MainActor.run {
                    self.deletionError = error.localizedDescription
                }
            }
        }
    }

    func clearTrashHistory() {
        trashHistory.removeAll()
        saveTrashHistory()
    }

    // MARK: - Hide/Unhide

    func hideNode(_ node: FileNode) {
        node.isHidden = true
        selectedNodes.remove(node)
        // If treemap is zoomed into the hidden node, zoom out
        if treemapRoot?.id == node.id {
            treemapRoot = node.parent
        }
        node.parent?.recalculateSizeUpward()
        hiddenNodes.append(node)
    }

    func unhideNode(_ node: FileNode) {
        node.isHidden = false
        node.parent?.recalculateSizeUpward()
        hiddenNodes.removeAll { $0.id == node.id }
    }

    func unhideAll() {
        for node in hiddenNodes {
            node.isHidden = false
            node.parent?.recalculateSizeUpward()
        }
        hiddenNodes.removeAll()
    }

    func startScan() {
        treemapRoot = nil
        selectedNodes.removeAll()
        hiddenNodes.removeAll()
        scanVM.startScan(mode: accessMode)
    }

    func stopScan() {
        scanVM.stopScan()
    }

    /// Called when scan completes — trigger suggestions detection
    func onScanComplete() {
        suggestionsVM.detect(scanRoot: scanVM.rootNode)
        refreshDiskSpace()
    }

    // MARK: - Directory Permissions

    var hasRestrictedDirectories: Bool {
        !scanVM.restrictedDirectories.isEmpty
    }

    func grantAccessToDirectory(_ node: FileNode) {
        scanVM.rescanDirectory(node)
    }

    func retryDeniedDirectory(_ node: FileNode) {
        node.isPermissionDenied = false
        node.awaitingPermission = true
        scanVM.rescanDirectory(node)
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Toggle access mode, checking FDA if needed
    func toggleAccessMode() {
        if accessMode == .userDirectory {
            if PermissionService.hasFullDiskAccess() {
                accessMode = .fullDisk
                hasFullDiskAccess = true
            } else {
                PermissionService.openFullDiskAccessSettings()
            }
        } else {
            accessMode = .userDirectory
        }
    }

    // MARK: - Deletion

    func confirmDeletion() {
        guard !selectedNodes.isEmpty else { return }
        showingDeleteConfirmation = true
    }

    func performDeletion() {
        let nodesToDelete = Array(selectedNodes)
        isDeleting = true
        deletionError = nil

        Task {
            do {
                for node in nodesToDelete {
                    let trashURL = try await deletionService.moveToTrash(url: node.url)
                    await MainActor.run {
                        self.recordTrashed(originalURL: node.url, trashURL: trashURL, size: node.size, source: .fileTree)
                        node.markAsTrashed(trashURL: trashURL)
                        self.selectedNodes.remove(node)
                    }
                }
                await MainActor.run {
                    self.isDeleting = false
                    self.showingDeleteConfirmation = false
                    // Refresh suggestions
                    self.suggestionsVM.detect(scanRoot: self.scanVM.rootNode)
                    self.refreshDiskSpace()
                }
            } catch {
                await MainActor.run {
                    self.deletionError = error.localizedDescription
                    self.isDeleting = false
                }
            }
        }
    }

    func deleteSuggestion(_ suggestion: SpaceWaster) {
        isDeleting = true
        Task {
            do {
                let trashURL = try await deletionService.moveToTrash(url: suggestion.url)
                await MainActor.run {
                    self.recordTrashed(originalURL: suggestion.url, trashURL: trashURL, size: suggestion.size, source: .suggestion)
                    self.markDeletedURLsInTree([suggestion.url], trashURLs: [trashURL])
                    self.isDeleting = false
                    self.suggestionsVM.detect(scanRoot: self.scanVM.rootNode)
                    self.refreshDiskSpace()
                }
            } catch {
                await MainActor.run {
                    self.deletionError = error.localizedDescription
                    self.isDeleting = false
                }
            }
        }
    }

    // MARK: - App Uninstall

    func performAppUninstall() {
        uninstallerVM.performUninstall(using: deletionService) { [weak self] originalURLs, trashedURLs, app in
            guard let self else { return }
            // Record each trashed item
            for (index, originalURL) in originalURLs.enumerated() {
                let trashURL = index < trashedURLs.count ? trashedURLs[index] : originalURL
                let size: Int64
                if originalURL == app.bundleURL {
                    size = app.bundleSize
                } else {
                    size = app.associatedFiles.first { $0.url == originalURL }?.size ?? 0
                }
                self.recordTrashed(originalURL: originalURL, trashURL: trashURL, size: size, source: .appUninstall)
            }
            self.markDeletedURLsInTree(originalURLs, trashURLs: trashedURLs)
            self.suggestionsVM.detect(scanRoot: self.scanVM.rootNode)
            self.refreshDiskSpace()
        }
    }

    // MARK: - Tree sync

    /// Mark nodes matching the given URLs as trashed in the scan tree and recalculate sizes.
    func markDeletedURLsInTree(_ urls: [URL], trashURLs: [URL]) {
        guard let root = scanVM.rootNode else { return }
        for (index, url) in urls.enumerated() {
            if let node = root.findNode(at: url) {
                // If treemap is zoomed into a deleted node, zoom out
                if treemapRoot?.id == node.id {
                    treemapRoot = node.parent
                }
                selectedNodes.remove(node)
                let trashURL = index < trashURLs.count ? trashURLs[index] : url
                node.markAsTrashed(trashURL: trashURL)
            }
        }
    }

    // MARK: - Reveal in Finder

    func revealInFinder(_ node: FileNode) {
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }

    /// Navigate the main view into a directory by URL (e.g. from suggestions)
    func navigateToDirectory(url: URL) {
        guard let root = scanVM.rootNode,
              let node = root.findNode(at: url),
              node.isDirectory else { return }
        selectedSidebarItem = .disk
        treemapRoot = node
    }

    // MARK: - Treemap navigation

    func zoomIntoNode(_ node: FileNode) {
        guard node.isDirectory else { return }
        treemapRoot = node
    }

    func zoomOut() {
        guard let current = treemapRoot else { return }
        treemapRoot = current.parent
    }

    func zoomToRoot() {
        treemapRoot = nil
    }

    /// Breadcrumb path from scan root to current treemap root
    var breadcrumbs: [FileNode] {
        var path: [FileNode] = []
        var current = treemapRoot
        while let node = current {
            path.insert(node, at: 0)
            current = node.parent
        }
        return path
    }

    // MARK: - Disk space info

    var diskSpaceInfo: (total: Int64, free: Int64, used: Int64)?

    func refreshDiskSpace() {
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(
            forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        ) else { return }

        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
        diskSpaceInfo = (total: total, free: free, used: total - free)
        diskSpaceHistory.record(freeBytes: free)
    }
}
