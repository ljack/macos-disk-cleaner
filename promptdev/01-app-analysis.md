# App Analysis — DiskCleaner

## What It Is

A native macOS (SwiftUI, macOS 14+) disk usage analyzer and cleaner. It scans the filesystem, visualizes disk usage as a treemap and file tree, detects known space wasters (Xcode caches, node_modules, etc.), and provides an app uninstaller that finds and removes associated data scattered across ~/Library.

## Architecture

**Pattern**: MVVM + Actor-based services
**UI Framework**: SwiftUI with AppKit interop (NSWorkspace, NSImage, Canvas)
**Concurrency**: Swift structured concurrency — actors for services, Task for async work
**State Management**: @Observable (Observation framework, not Combine)
**Navigation**: NavigationSplitView with sidebar + detail

## File Map

```
DiskCleaner/
├── DiskCleanerApp.swift              # @main entry, WindowGroup, environment injection
├── Models/
│   ├── FileNode.swift                # Reference-type tree node (class, not struct)
│   ├── ScanResult.swift              # Scan metadata wrapper
│   ├── SpaceWaster.swift             # Space waster category + detected item
│   ├── DiskAccessMode.swift          # Home vs Full Disk enum
│   └── InstalledApp.swift            # Installed app + associated files model
├── Services/
│   ├── ScanningEngine.swift          # Actor: recursive filesystem scanner
│   ├── SuggestionsEngine.swift       # Actor: detects known space wasters
│   ├── DeletionService.swift         # Actor: moves files to Trash
│   ├── PermissionService.swift       # Enum: Full Disk Access check/prompt
│   └── AppDiscoveryEngine.swift      # Actor: discovers apps + associated files
├── ViewModels/
│   ├── AppViewModel.swift            # Central coordinator (owns all sub-VMs)
│   ├── ScanViewModel.swift           # Scan state machine (status, progress, results)
│   ├── SuggestionsViewModel.swift    # Smart suggestions state
│   └── AppUninstallerViewModel.swift # App uninstaller state
├── Views/
│   ├── MainWindowView.swift          # NavigationSplitView shell, routes sidebar selection
│   ├── ToolbarView.swift             # Toolbar: scan button, view toggle, access mode, delete
│   ├── SidebarView.swift             # Sidebar: disk, apps, suggestions, total
│   ├── TreeView/
│   │   ├── FileTreeView.swift        # OutlineGroup file tree
│   │   └── FileTreeRowView.swift     # Row: checkbox, icon, name, size bar
│   ├── TreemapView/
│   │   ├── TreemapContainerView.swift # Breadcrumbs + canvas + legend
│   │   └── TreemapCanvasView.swift   # Canvas-rendered interactive treemap
│   ├── Suggestions/
│   │   └── SuggestionsListView.swift # Category detail: risk badge, items, clean buttons
│   ├── Apps/
│   │   ├── AppListView.swift         # HSplitView: searchable app list + detail
│   │   ├── AppDetailView.swift       # App detail: icon, sizes, associated files
│   │   └── UninstallConfirmationSheet.swift # Uninstall confirmation modal
│   └── Shared/
│       ├── ConfirmationSheet.swift   # Delete confirmation modal
│       ├── ProgressOverlayView.swift # Scan progress overlay
│       └── ScanButtonView.swift      # Dual-style scan button (toolbar + hero)
├── Algorithms/
│   └── SquarifiedTreemap.swift       # Squarified treemap layout algorithm
└── Utilities/
    ├── FileTypeClassifier.swift      # Extension → category mapping for treemap colors
    └── URLExtensions.swift           # URL helpers: systemIcon, isDirectory, fileSize
```

## Feature Inventory

### F1: Disk Scanning
- Recursive filesystem scan from home dir or root
- Progress reporting (throttled every 500 files)
- Cancellation support via Task
- FileNode tree with parent/child refs, bottom-up size calculation
- Two access modes: Home Directory, Full Disk (with FDA check)

### F2: File Tree View
- Hierarchical OutlineGroup with alternating row backgrounds
- Per-row: checkbox selection, file type icon, name, descendant count, size bar, formatted size
- Size bars color-coded by fraction of parent (red >50%, orange >20%, blue)

### F3: Treemap Visualization
- Squarified treemap algorithm for near-square rectangles
- Canvas rendering with depth-based opacity
- Hover highlighting with tooltip (name, size, item count)
- Double-click to zoom into directories
- Breadcrumb navigation bar
- Color legend by file type category

### F4: Smart Suggestions
- Detects 10 categories of known space wasters
- Concurrent checking of standard locations
- Finds node_modules in scan tree
- Risk levels (safe/moderate) with color coding
- Per-item "Clean" button (moves to Trash)

### F5: Deletion
- Moves to Trash (undoable) via FileManager.trashItem
- Batch deletion with confirmation sheet
- Updates tree and recalculates sizes after deletion
- Refreshes suggestions post-deletion

### F6: App Uninstaller
- Scans /Applications, /Applications/Utilities, ~/Applications
- Reads bundle identifiers from Info.plist
- Finds associated files in 8 ~/Library subdirectories
- Searchable/sortable app list with icons and sizes
- Detail view with size cards and categorized associated files
- Uninstall confirmation sheet listing everything to be trashed

### F7: Toolbar & Status
- Scan button with 7 status states and color tinting
- View mode toggle (list/treemap)
- Access mode toggle with FDA gate
- Delete selected items button
- Disk space usage bar

## Key Design Decisions

1. **FileNode is a class** — reference semantics for efficient large tree (millions of nodes), parent/child relationships, in-place mutation
2. **Services are actors** — thread-safe filesystem operations without manual locking
3. **@Observable not ObservableObject** — modern Observation framework, no @Published needed
4. **Central AppViewModel** — coordinator pattern, owns all sub-VMs and services, injected via @Environment
5. **DeletionService is shared** — both file deletion and app uninstall reuse the same service
6. **No Combine** — pure async/await with Task and MainActor.run
7. **ByteCountFormatter** — consistent human-readable sizes everywhere via .file count style
