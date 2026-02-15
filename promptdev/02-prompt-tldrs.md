# Prompt TL;DRs

Each entry represents one logical build step that was (or could have been) a single LLM prompt. Together they form the prompt chain that built DiskCleaner.

---

## P1: Project Scaffold
**TL;DR**: Create a new macOS SwiftUI app target (macOS 14+) with MVVM folder structure.
- Creates: Xcode project, DiskCleanerApp.swift, folder groups (Models, Services, ViewModels, Views, Algorithms, Utilities)
- Output: Empty app that launches a window

## P2: Core Models
**TL;DR**: Define the filesystem tree model and scan metadata.
- Creates: FileNode.swift (reference-type tree node with parent/child, size rollup, Hashable), ScanResult.swift (scan metadata wrapper), DiskAccessMode.swift (home vs full disk enum)
- Key decision: FileNode is a `class` for reference semantics in large trees

## P3: Scanning Engine
**TL;DR**: Build an actor that recursively scans the filesystem with progress and cancellation.
- Creates: ScanningEngine.swift (actor), ScanViewModel.swift (@Observable with ScanStatus state machine)
- Features: recursive scan, symlink skipping, permission handling, throttled progress callbacks, Task cancellation
- Creates: URLExtensions.swift (systemIcon, isDirectory, fileSize helpers)

## P4: Main Window + Navigation Shell
**TL;DR**: Set up NavigationSplitView with sidebar and detail routing.
- Creates: MainWindowView.swift (NavigationSplitView shell), SidebarView.swift (disk section), AppViewModel.swift (central coordinator)
- Creates: ToolbarView.swift (scan button, view toggle, access mode, delete action, disk space bar)
- Creates: ScanButtonView.swift (dual-style: toolbar compact + hero empty state with 7 status states)
- Wires: @Environment injection of AppViewModel, scan trigger, view mode toggle

## P5: File Tree View
**TL;DR**: Render the scanned filesystem as an expandable tree with selection and size bars.
- Creates: FileTreeView.swift (OutlineGroup with optionalChildren extension), FileTreeRowView.swift
- Features: checkbox selection, file type icons, name + descendant count, proportional size bar (red/orange/blue), formatted size
- Creates: FileTypeClassifier.swift (extension-to-category mapping, 6 categories + directory + other)
- Creates: ProgressOverlayView.swift (scan progress with stop button)

## P6: Treemap Visualization
**TL;DR**: Implement squarified treemap algorithm and interactive Canvas rendering.
- Creates: SquarifiedTreemap.swift (pure algorithm: squarify, layout, worstAspectRatio)
- Creates: TreemapCanvasView.swift (Canvas rendering, hover, double-click zoom), TreemapContainerView.swift (breadcrumbs + legend)
- Features: depth-based opacity, hover tooltip, zoom navigation, file type color legend
- Adds: treemap navigation to AppViewModel (zoomInto, zoomOut, zoomToRoot, breadcrumbs)

## P7: Smart Suggestions
**TL;DR**: Detect known space-wasting directories and offer one-click cleanup.
- Creates: SpaceWaster.swift (10 categories with icons, risk levels, descriptions), SuggestionsEngine.swift (actor, concurrent detection)
- Creates: SuggestionsViewModel.swift (@Observable), SuggestionsListView.swift (category detail with Clean buttons)
- Features: checks 9 standard locations concurrently, finds node_modules in scan tree, risk badges
- Integrates: sidebar suggestion categories, deleteSuggestion flow

## P8: Deletion System
**TL;DR**: Build safe file deletion via Trash with confirmation UI.
- Creates: DeletionService.swift (actor, FileManager.trashItem), ConfirmationSheet.swift (modal with item list, sizes, total)
- Creates: PermissionService.swift (FDA check + System Settings opener)
- Integrates: confirmDeletion/performDeletion in AppViewModel, tree update after deletion, suggestion refresh

## P9: App Uninstaller
**TL;DR**: Scan installed apps, find associated data in ~/Library, uninstall with confirmation.
- Creates: InstalledApp.swift (model with AssociatedFile, AssociatedFileCategory)
- Creates: AppDiscoveryEngine.swift (actor: scans 3 app dirs, reads bundle IDs, searches 8 ~/Library paths)
- Creates: AppUninstallerViewModel.swift (@Observable: search, sort, uninstall flow)
- Creates: AppListView.swift (HSplitView list + detail), AppDetailView.swift (size cards, categorized files), UninstallConfirmationSheet.swift
- Integrates: SidebarItem.apps, sidebar "Applications" section, MainWindowView routing, uninstall sheet

## P10: Polish & Integration
**TL;DR**: Wire everything together, update pbxproj, fix build errors, verify.
- Updates: project.pbxproj with all file references, build files, group hierarchy
- Fixes: @Bindable binding issues for nested observable properties
- Verifies: clean build, all features accessible, navigation working
