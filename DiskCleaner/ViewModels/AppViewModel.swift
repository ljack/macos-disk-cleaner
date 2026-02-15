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
    case apps
    case suggestion(SpaceWasterCategory)
}

/// Central coordinator ViewModel
@Observable
final class AppViewModel {
    let scanVM = ScanViewModel()
    let suggestionsVM = SuggestionsViewModel()
    let uninstallerVM = AppUninstallerViewModel()
    let deletionService = DeletionService()

    var accessMode: DiskAccessMode = .userDirectory
    var viewMode: ViewMode = .list
    var selectedSidebarItem: SidebarItem? = .disk
    var hasFullDiskAccess: Bool = false

    // Selection for deletion
    var selectedNodes: Set<FileNode> = []

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
    }

    func startScan() {
        treemapRoot = nil
        selectedNodes.removeAll()
        scanVM.startScan(mode: accessMode)
    }

    func stopScan() {
        scanVM.stopScan()
    }

    /// Called when scan completes — trigger suggestions detection
    func onScanComplete() {
        suggestionsVM.detect(scanRoot: scanVM.rootNode)
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
                    try await deletionService.moveToTrash(url: node.url)
                    await MainActor.run {
                        // Remove from tree and recalculate
                        node.parent?.removeChild(node)
                        self.selectedNodes.remove(node)
                    }
                }
                await MainActor.run {
                    self.isDeleting = false
                    self.showingDeleteConfirmation = false
                    // Refresh suggestions
                    self.suggestionsVM.detect(scanRoot: self.scanVM.rootNode)
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
                try await deletionService.moveToTrash(url: suggestion.url)
                await MainActor.run {
                    self.isDeleting = false
                    // Refresh suggestions and re-scan if we have results
                    self.suggestionsVM.detect(scanRoot: self.scanVM.rootNode)
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
        uninstallerVM.performUninstall(using: deletionService)
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

    var diskSpaceInfo: (total: Int64, free: Int64, used: Int64)? {
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(
            forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        ) else { return nil }

        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
        return (total: total, free: free, used: total - free)
    }
}
