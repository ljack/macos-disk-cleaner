# Runnable Prompt Chain — DiskCleaner

Execute these prompts sequentially in an LLM coding agent to reproduce the application from scratch. Each prompt is self-contained with context, requirements, and acceptance criteria.

**Prerequisites**: Xcode 15+, macOS 14+ SDK

---

## Prompt 1: Project Scaffold

```
Create a new macOS SwiftUI application called "DiskCleaner" targeting macOS 14+.

Requirements:
- App entry point: DiskCleanerApp.swift using @main, WindowGroup, .titleBar style, default size 1100x700
- Create empty folder groups: Models, Services, ViewModels, Views (with subgroups: TreeView, TreemapView, Suggestions, Shared), Algorithms, Utilities
- Swift strict concurrency: complete
- Bundle ID: com.diskcleaner.app
- Category: public.app-category.utilities
- Add entitlements file: DiskCleaner.entitlements

The app should launch and show an empty window. Use @State to create an AppViewModel instance (just an empty @Observable class for now) and inject it via .environment().

Acceptance: App builds and launches with empty window.
```

---

## Prompt 2: Core Models

```
In the DiskCleaner project, create the core data models.

File: Models/FileNode.swift
- final class FileNode: Identifiable (NOT a struct — we need reference semantics for million-node trees)
- Properties: id (UUID), url (URL), name (String), isDirectory (Bool), size (Int64), children ([FileNode]), parent (weak FileNode?), isPermissionDenied (Bool), descendantCount (Int)
- init(url:, name:, isDirectory:, size: 0, children: [])
- finalizeTree() — recursively calculates size bottom-up from children, counts descendants, sorts children by size descending
- removeChild(_ child:) — removes child by id, calls recalculateSizeUpward()
- recalculateSizeUpward() — recalculates own size/descendantCount, propagates to parent
- formattedSize: String — ByteCountFormatter.string(fromByteCount:countStyle: .file)
- fractionOfParent: Double — size / parent.size (1.0 if no parent)
- Hashable conformance via extension, equality and hash by id only

File: Models/ScanResult.swift
- struct ScanResult with: root (FileNode), scanDate (Date), duration (TimeInterval), totalFiles (Int), totalDirectories (Int), accessMode (DiskAccessMode)
- Computed: totalItems = totalFiles + totalDirectories

File: Models/DiskAccessMode.swift
- enum DiskAccessMode: String, CaseIterable with cases: userDirectory ("Home Directory"), fullDisk ("Full Disk")
- rootURL: URL — homeDirectoryForCurrentUser vs "/"
- icon: String — "house" vs "internaldrive"

Acceptance: All three files compile with no errors.
```

---

## Prompt 3: Scanning Engine + Scan ViewModel

```
Build the filesystem scanning service and its view model.

File: Utilities/URLExtensions.swift
- Extension on URL with:
  - systemIcon: NSImage — NSWorkspace.shared.icon(forFile: path)
  - isDirectory: Bool — resourceValues isDirectoryKey
  - fileSize: Int64 — totalFileAllocatedSize ?? fileSize ?? 0

File: Services/ScanningEngine.swift
- Actor ScanningEngine
- Struct ScanProgress: Sendable with filesScanned, directoriesScanned, currentPath, bytesScanned
- Private state: filesScanned, directoriesScanned, bytesScanned counters, progressInterval = 500
- Resource keys: isDirectoryKey, isSymbolicLinkKey, fileSizeKey, totalFileAllocatedSizeKey, nameKey
- func scan(root: URL, onProgress: @Sendable @escaping (ScanProgress) -> Void) async throws -> FileNode
  - Resets counters, calls scanDirectory recursively, finalizes tree, sends final progress
- private scanDirectory(url:, parent:, onProgress:) — checks cancellation, creates FileNode, reads directory contents (.skipsHiddenFiles), handles permission denied, skips symlinks, recurses into directories, counts files/bytes, reports progress every 500 files

File: ViewModels/ScanViewModel.swift
- enum ScanStatus: Equatable with 7 cases: readyToScan, scanning, complete, resultsAging, outdated, stopped, failed(String)
  - Each case has: label, icon (SF Symbol), subtitle, canStartScan, canStopScan
- @Observable final class ScanViewModel
  - Properties: isScanning, scanResult, progress (ScanProgress?), errorMessage, wasCancelled
  - Private: engine (ScanningEngine), scanTask (Task?)
  - Computed: rootNode (scanResult?.root), status (derived from state — scanning/failed/stopped/readyToScan, then age-based: <5min complete, <1hr aging, else outdated)
  - startScan(mode:) — guards !isScanning, resets state, creates Task that calls engine.scan with MainActor progress callback, wraps result in ScanResult, handles CancellationError and general errors
  - stopScan() — cancels and nils the task

Acceptance: Files compile. ScanViewModel can be instantiated and startScan/stopScan called.
```

---

## Prompt 4: Main Window, Navigation Shell, Toolbar

```
Create the main window layout with sidebar navigation, toolbar, and the central coordinator ViewModel.

File: ViewModels/AppViewModel.swift
- enum ViewMode: String, CaseIterable — list ("List", icon "list.bullet"), treemap ("Treemap", icon "square.grid.2x2")
- enum SidebarItem: Hashable — .disk, .apps, .suggestion(SpaceWasterCategory)
- @Observable final class AppViewModel
  - Owns: scanVM (ScanViewModel), deletionService (DeletionService — create empty actor for now)
  - State: accessMode (.userDirectory), viewMode (.list), selectedSidebarItem (.disk), hasFullDiskAccess
  - Selection: selectedNodes (Set<FileNode>)
  - Deletion: showingDeleteConfirmation, isDeleting, deletionError
  - Treemap: treemapRoot (FileNode?), displayedRoot (treemapRoot ?? scanVM.rootNode), breadcrumbs ([FileNode] computed path)
  - Init: checks PermissionService.hasFullDiskAccess()
  - Methods: startScan(), stopScan(), onScanComplete(), toggleAccessMode() (with FDA gate), zoomIntoNode/zoomOut/zoomToRoot, diskSpaceInfo (volumeTotalCapacity, volumeAvailableCapacityForImportantUsage)

File: Services/PermissionService.swift
- enum PermissionService (no instances)
- static hasFullDiskAccess() -> Bool — test read ~/Library/Mail
- static openFullDiskAccessSettings() — open x-apple.systempreferences URL

File: Views/MainWindowView.swift
- NavigationSplitView { SidebarView() } detail: { detailContent }
- .toolbar { ToolbarView() }
- .sheet for deletion confirmation
- detailContent switches on selectedSidebarItem: .apps, .suggestion(category), .disk/nil
- diskContent: if rootNode exists show FileTreeView/TreemapContainerView based on viewMode, else hero ScanButtonView

File: Views/SidebarView.swift
- @Environment(AppViewModel.self), @Bindable for selection binding
- List(selection:) with sections: "Disk" (access mode + scan size), "Smart Suggestions" (grouped categories with size badges), total reclaimable
- groupedSuggestions computed property groups by SpaceWasterCategory.allCases order

File: Views/ToolbarView.swift (ToolbarContent protocol)
- Navigation: ScanButtonView(.toolbar)
- Primary actions: ViewMode segmented picker, access mode button, delete N items button (conditional)
- Status: disk space bar (GeometryReader, used fraction, red >90%)

File: Views/Shared/ScanButtonView.swift
- enum ScanButtonStyle: toolbar, hero
- Reads status from appVM.scanVM.status
- Toolbar: borderedProminent button with status icon + label, tinted by status
- Hero: large circular icon with gradient, inline progress during scan, result summary after completion, stop button
- 7 status colors: accentColor, orange, green, yellow, orange, secondary, red
- handleTap: stop if scanning, start if canStartScan

Update DiskCleanerApp.swift to use the real AppViewModel with .environment() injection.

Acceptance: App launches with sidebar showing "Disk" section, toolbar with scan button, empty state hero scan button in detail area.
```

---

## Prompt 5: File Tree View

```
Implement the file tree view showing scan results as an expandable hierarchical list.

File: Utilities/FileTypeClassifier.swift
- enum FileTypeCategory: String, CaseIterable — code, media, documents, archives, system, data, directory, other
  - Each has: color (Color), icon (SF Symbol)
- enum FileTypeClassifier with static classify(url:) -> FileTypeCategory
  - Maps file extensions to categories via private static Set<String> properties:
    - code: swift, py, js, ts, json, yaml, html, css, etc. (~40 extensions)
    - media: jpg, png, mp4, psd, etc. (~35 extensions)
    - documents: doc, txt, pdf, csv, md, etc. (~20 extensions)
    - archives: zip, tar, dmg, pkg, etc. (~13 extensions)
    - system: dylib, framework, app, log, etc. (~10 extensions)
    - data: db, sqlite, realm, etc. (~6 extensions)

File: Views/TreeView/FileTreeView.swift
- Takes root: FileNode
- List with OutlineGroup(root.children, children: \.optionalChildren) rendering FileTreeRowView
- .listStyle(.inset(alternatesRowBackgrounds: true))
- Extension on FileNode: optionalChildren — returns children if directory and non-empty, else nil

File: Views/TreeView/FileTreeRowView.swift
- HStack: checkbox toggle (bound to appVM.selectedNodes), file icon, name + descendant count, size bar, size label
- fileIcon: lock.fill (red) if permission denied, folder.fill (blue) if directory, else FileTypeClassifier icon+color
- sizeBar: GeometryReader with proportional fill, color by fractionOfParent (red >50%, orange >20%, blue)
- Size label: .caption.monospacedDigit(), 70pt width

File: Views/Shared/ProgressOverlayView.swift
- VStack: ProgressView, "Scanning..." title, progress details (files/dirs/bytes/path), stop button
- .ultraThinMaterial background with rounded corners

Acceptance: After scanning, file tree shows expandable hierarchy with checkboxes, icons, size bars.
```

---

## Prompt 6: Treemap Visualization

```
Implement the squarified treemap algorithm and interactive treemap view.

File: Algorithms/SquarifiedTreemap.swift
- struct TreemapRect: Identifiable — id (UUID), node (FileNode), rect (CGRect), depth (Int), color (FileTypeCategory)
- enum SquarifiedTreemap with static layout(node:, bounds:, maxDepth: 2, currentDepth: 0, minSize: 20) -> [TreemapRect]
  - Filters children with size > 0
  - Normalizes sizes to areas proportional to bounds
  - Calls squarify() to get rectangles
  - Recursively layouts directory children up to maxDepth
  - Skips rects smaller than minSize
- private static squarify(areas:, bounds:) -> [CGRect]
  - Greedy row-building: adds items while aspect ratio improves
  - Lays out rows horizontally or vertically based on shorter dimension
  - Adjusts remaining bounds after each row
- private static worstAspectRatio(row:, shorter:) -> Double

File: Views/TreemapView/TreemapCanvasView.swift
- @State: hoveredRect, layoutRects, canvasSize
- GeometryReader with Canvas for rendering
- Recalculates layout on size change, root change, and appear
- drawTreemap: background fill, sort by depth, fill rects with depth-based opacity, border (white on hover), labels on rects > 50x20
- Hit testing for hover and double-click zoom
- Tooltip overlay: name, size, item count, "Double-click to zoom in"
- Extension on FileTypeCategory: nsColor computed property

File: Views/TreemapView/TreemapContainerView.swift
- VStack: breadcrumbBar, Divider, TreemapCanvasView, Divider, legendBar
- breadcrumbBar: Home icon + breadcrumb buttons from appVM.breadcrumbs, root size
- legendBar: HStack of FileTypeCategory.allCases with colored circles + labels

Acceptance: Treemap renders after scan, colors by file type, hover highlights, double-click zooms, breadcrumbs navigate.
```

---

## Prompt 7: Smart Suggestions

```
Build the space waster detection system.

File: Models/SpaceWaster.swift
- enum SpaceWasterCategory: String, CaseIterable, Identifiable — 10 cases:
  xcodeDerivedData, xcodeArchives, xcodeDeviceSupport, nodeModules, userCaches, dotCache, logs, homebrewCache, dockerData, trash
  - Each has: icon (SF Symbol), riskLevel (safe/moderate), description (human-readable explanation)
- enum RiskLevel: String — safe ("Safe"), moderate ("Moderate"), with color property
- struct SpaceWaster: Identifiable — id (UUID), category, url, size (Int64), itemCount, formattedSize

File: Services/SuggestionsEngine.swift
- Actor SuggestionsEngine
- detectAll(scanRoot: FileNode?) async -> [SpaceWaster]
  - Uses async let for 9 concurrent directory checks in ~/Library and ~/.cache and ~/.Trash
  - Finds node_modules from scan tree if available
  - Returns sorted by size descending
- private checkDirectory(_ url:, category:) -> SpaceWaster? — checks existence, calculates size
- private directorySize(_ url:) -> (Int64, Int) — enumerates files, sums totalFileAllocatedSize
- private findNodeModules(in: FileNode) -> [SpaceWaster] — recursive tree walk

File: ViewModels/SuggestionsViewModel.swift
- @Observable final class with: suggestions, isDetecting, totalWastedSpace (computed), formattedTotalWaste
- func detect(scanRoot:) — fires Task, calls engine.detectAll, updates on MainActor

File: Views/Suggestions/SuggestionsListView.swift
- Takes category: SpaceWasterCategory
- Filters suggestions by category
- Header: icon + name + description + risk badge (green circle for safe, orange for moderate)
- List of items: name, path (truncated from head), size, "Clean" button (red, calls appVM.deleteSuggestion)

Update AppViewModel:
- Add suggestionsVM property
- onScanComplete() triggers suggestionsVM.detect()
- Add deleteSuggestion(_ suggestion:) method — moves to trash, refreshes suggestions

Update SidebarView:
- Add "Smart Suggestions" section showing grouped categories with size capsule badges
- Add "Total reclaimable" section at bottom

Update MainWindowView:
- Route .suggestion(category) to SuggestionsListView
- onChange: trigger onScanComplete when scan finishes

Acceptance: After scan, sidebar shows detected space wasters grouped by category. Clicking shows items with Clean buttons.
```

---

## Prompt 8: Deletion System

```
Implement file deletion with confirmation UI.

File: Services/DeletionService.swift
- Actor DeletionService
- moveToTrash(urls: [URL]) async throws -> [URL] — MainActor.run, FileManager.trashItem for each URL, returns trashed URLs
- moveToTrash(url: URL) async throws — single file convenience

File: Views/Shared/ConfirmationSheet.swift
- Reads from appVM: selectedNodes, showingDeleteConfirmation, isDeleting, deletionError
- VStack: trash icon (red), "Move to Trash?" title, item count, scrollable list (sorted by size, icon + name + size), total size, error display, Cancel + "Move to Trash" buttons
- Cancel sets showingDeleteConfirmation = false
- Confirm calls appVM.performDeletion()
- Frame width: 450, scroll maxHeight: 200

Update AppViewModel:
- Add deletionService (DeletionService)
- confirmDeletion() — guards non-empty selection, shows sheet
- performDeletion() — iterates selectedNodes, trashes each, removes from tree via parent.removeChild(), recalculates sizes, refreshes suggestions, dismisses sheet
- Error handling: sets deletionError on failure

Update MainWindowView:
- Add .sheet(isPresented: $appVM.showingDeleteConfirmation) { ConfirmationSheet() }

Acceptance: Select files in tree, click Delete in toolbar, confirmation shows items and sizes, confirm moves to Trash.
```

---

## Prompt 9: App Uninstaller

```
Build the app uninstaller feature that discovers installed apps and their associated data.

File: Models/InstalledApp.swift
- enum AssociatedFileCategory: String, CaseIterable — applicationSupport, caches, preferences, savedState, logs, containers, httpStorages, webKit
  - Each has: rawValue (display name), icon (SF Symbol)
- struct AssociatedFile: Identifiable — id (UUID), url, size (Int64), category, formattedSize
- struct InstalledApp: Identifiable, Hashable — id (UUID), name, bundleIdentifier (String?), bundleURL, bundleSize (Int64), icon (NSImage), associatedFiles ([AssociatedFile])
  - Computed: associatedSize, totalSize, formattedBundleSize, formattedAssociatedSize, formattedTotalSize
  - Hashable/Equatable by id only

File: Services/AppDiscoveryEngine.swift
- Actor AppDiscoveryEngine
- discoverApps() async -> [InstalledApp]
  - Scans: /Applications, /Applications/Utilities, ~/Applications
  - For each .app: reads Bundle(url:).bundleIdentifier, gets icon via NSWorkspace on MainActor, calculates bundle directory size
  - Finds associated files, returns sorted by totalSize descending
- private findAssociatedFiles(bundleIdentifier:, appName:) -> [AssociatedFile]
  - By bundle ID AND app name: Application Support, Caches, Logs (avoids duplicate if name == bundleId)
  - By bundle ID only: Preferences/{id}.plist, Saved Application State/{id}.savedState, Containers/{id}, HTTPStorages/{id}, WebKit/{id}
  - Returns sorted by size descending
- private directorySize(_ url:) -> Int64 — same pattern as SuggestionsEngine

File: ViewModels/AppUninstallerViewModel.swift
- enum AppSortOrder: String, CaseIterable — totalSize, name, appSize, dataSize
- @Observable final class AppUninstallerViewModel
  - State: apps, isScanning, selectedApp, searchText, sortOrder (.totalSize), uninstall flow (appToUninstall, showingUninstallConfirmation, isUninstalling, uninstallError)
  - Computed: displayedApps (filtered by searchText, sorted by sortOrder)
  - discoverApps() — Task calling engine, updates on MainActor
  - requestUninstall(_ app:) — sets appToUninstall, shows confirmation
  - performUninstall(using: DeletionService) — collects bundle + associated URLs, trashes all, removes from list, clears selection
  - cancelUninstall() — resets uninstall state

File: Views/Apps/AppListView.swift
- HSplitView: left list (300pt min), right detail
- Left: search bar (magnifyingglass + TextField + sort Picker), app list or states (scanning/empty)
- List with selection binding to selectedApp
- AppRowView: 32pt icon, name + bundleId, total size + "+data" badge
- Right: AppDetailView or placeholder
- onAppear: auto-discovers if empty

File: Views/Apps/AppDetailView.swift
- ScrollView with VStack
- Header: 64pt icon, name, bundleId (selectable), path, Uninstall button (red borderedProminent)
- 3 SizeCardView cards: App Bundle (blue), Associated Data (orange), Total (red)
- Associated files grouped by AssociatedFileCategory.allCases
- Each group: category icon + name + size, then individual files indented
- Empty state: green checkmark "No associated data found"
- SizeCardView: icon + size + title in .fill.quaternary rounded rect

File: Views/Apps/UninstallConfirmationSheet.swift
- Shows appToUninstall info: 48pt icon, "Uninstall {name}?", explanation text
- Scrollable item list: .app bundle (blue icon) + associated files (orange category icons) with sizes
- Total size, error display, Cancel + "Move to Trash" buttons
- Cancel calls cancelUninstall(), confirm calls appVM.performAppUninstall()
- Frame width: 450, scroll maxHeight: 200

Update AppViewModel:
- Add uninstallerVM (AppUninstallerViewModel)
- Add performAppUninstall() — calls uninstallerVM.performUninstall(using: deletionService)

Update SidebarView:
- Add "Applications" section between Disk and Smart Suggestions
- Label "App Uninstaller" with trash.square icon
- Badge showing app count in capsule
- Tagged as SidebarItem.apps

Update MainWindowView:
- Route .apps to AppListView()
- Add .sheet for uninstallerVM.showingUninstallConfirmation -> UninstallConfirmationSheet
- Use @Bindable on uninstallerVM for the sheet binding (nested @Observable requires separate @Bindable)

Acceptance: Click "App Uninstaller" in sidebar, apps auto-discover, list shows icons+sizes, detail shows breakdown, uninstall confirmation works.
```

---

## Prompt 10: Final Integration & Build Verification

```
Ensure all files are registered in the Xcode project and the app builds cleanly.

1. Verify project.pbxproj has entries for ALL Swift files in:
   - PBXBuildFile section (build file refs)
   - PBXFileReference section (file refs)
   - PBXGroup sections (correct parent groups including new "Apps" group under Views)
   - PBXSourcesBuildPhase (all sources listed)

2. Verify the Views group hierarchy:
   Views/
   ├── MainWindowView.swift
   ├── ToolbarView.swift
   ├── SidebarView.swift
   ├── TreeView/ (FileTreeView, FileTreeRowView)
   ├── TreemapView/ (TreemapContainerView, TreemapCanvasView)
   ├── Suggestions/ (SuggestionsListView)
   ├── Apps/ (AppListView, AppDetailView, UninstallConfirmationSheet)
   └── Shared/ (ConfirmationSheet, ProgressOverlayView, ScanButtonView)

3. Build with: xcodebuild -scheme DiskCleaner -configuration Debug build

4. Fix any compilation errors (common issues: @Bindable needed for nested @Observable properties in sheet bindings)

5. Verify all navigation paths work:
   - Sidebar .disk -> disk content (tree/treemap)
   - Sidebar .apps -> AppListView
   - Sidebar .suggestion(category) -> SuggestionsListView

Acceptance: BUILD SUCCEEDED with zero errors.
```

---

## Usage Notes

- Prompts 1-3 are foundational — must run first in order
- Prompts 4-6 build the UI layer — depend on models and services
- Prompt 7 (suggestions) and 8 (deletion) can be done in either order
- Prompt 9 (app uninstaller) depends on all previous prompts
- Prompt 10 is always last — integration verification
- Each prompt should produce compilable code before moving to the next
- The agent should read existing files before modifying them to understand current patterns
