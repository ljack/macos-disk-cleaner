# Golden First Prompt — One-Shot Rebuild

Use this as the first (and ideally only) prompt in an LLM coding agent to recreate the current DiskCleaner implementation as closely as possible.

```text
You are a senior macOS SwiftUI engineer. Build a complete app called "DiskCleaner" that matches a production-quality prompt-native implementation.

Goal:
Create a native macOS 14+ disk analysis/cleanup utility with:
1) recursive scan + progress + cancellation,
2) file tree + treemap visualization,
3) smart cleanup suggestions,
4) safe trash-based deletion,
5) app uninstaller with associated-data discovery,
6) trash history with restore,
7) promptdev documentation artifacts for reproducibility.

Tech constraints:
- SwiftUI, macOS 14+, Swift 5.9+
- Observation framework: use @Observable (not ObservableObject/@Published)
- Concurrency via async/await + actors
- No third-party runtime dependencies
- Use FileManager.trashItem for deletion (undoable)
- Keep architecture MVVM + actor services
- Inject coordinator VM via `.environment(...)`

Project structure:
- DiskCleaner/
  - Models: FileNode, ScanResult, DiskAccessMode, SpaceWaster, InstalledApp, TrashedItem
  - Services: ScanningEngine, SuggestionsEngine, DeletionService, PermissionService, AppDiscoveryEngine
  - ViewModels: AppViewModel, ScanViewModel, SuggestionsViewModel, AppUninstallerViewModel
  - Views:
    - MainWindowView, SidebarView, ToolbarView
    - TreeView: FileTreeView, FileTreeRowView
    - TreemapView: TreemapContainerView, TreemapCanvasView
    - Suggestions: SuggestionsListView
    - Apps: AppListView, AppDetailView, UninstallConfirmationSheet
    - Shared: ScanButtonView, ProgressOverlayView, ConfirmationSheet, TrashHistoryView
  - Algorithms: SquarifiedTreemap
  - Utilities: URLExtensions, FileTypeClassifier
- Also include: DiskCleanerApp.swift, entitlements, and Xcode project wiring (pbxproj entries/groups/sources).

Core behavior requirements:
- Scan states: ready, scanning, complete, aging, outdated, stopped, failed.
- Scan root modes: Home Directory vs Full Disk, with Full Disk Access check/prompt.
- Scan engine:
  - actor-based recursive traversal,
  - skip symlinks,
  - skip hidden files,
  - mark permission-denied directories gracefully,
  - throttle progress updates.
- Tree model:
  - FileNode must be a class (reference semantics),
  - parent links, descendant count, size rollups,
  - child removal + upward recalculation,
  - URL-based node lookup for post-delete sync,
  - trashed-state support (isTrashed + trashURL) and restore unmarking.
- File tree UI:
  - OutlineGroup hierarchy,
  - checkbox selection per node,
  - icon classification by file type,
  - size bar color by fraction of parent,
  - context menu on `.app` rows to launch uninstall flow,
  - for trashed nodes show dimmed state and Restore action.
- Treemap:
  - squarified layout algorithm,
  - hover tooltip,
  - double-click zoom into directories,
  - breadcrumbs and legend.
- Smart suggestions:
  - detect categories (xcode caches/archives/device support, node_modules, user caches, dot-cache, logs, homebrew cache, docker data, trash),
  - show grouped in sidebar with size badges,
  - category detail page with risk badge and clean button.
- Deletion:
  - confirmation sheet with items and total size,
  - move selected nodes to Trash,
  - return/store resulting trash URLs,
  - mark nodes as trashed in tree model and refresh suggestions.
- App uninstaller:
  - discover apps in /Applications, /Applications/Utilities, ~/Applications,
  - resolve bundle ID + icon + bundle size,
  - find associated files in ~/Library domains (Application Support, Caches, Logs, Preferences plist, Saved State, Containers, HTTPStorages, WebKit),
  - searchable/sortable app list,
  - detail screen with size cards and grouped associated files,
  - uninstall confirmation sheet,
  - uninstall should return original+trash URLs, sync tree, and refresh suggestions.
- Trash history:
  - persist history in UserDefaults,
  - record source (file tree / suggestion / app uninstall), size, original/trash URLs, timestamp,
  - sidebar history destination,
  - dedicated TrashHistoryView with list, clear history, and restore actions,
  - restore should move item from Trash back to original location and update tree/suggestions/history.
- Extra UX parity:
  - app icon/title row in sidebar,
  - scan timestamp + duration in sidebar disk row,
  - auto-scan on launch settings in sidebar,
  - configurable delay (0/3/5/10s),
  - hero scan button countdown + cancel.

UI shell requirements:
- NavigationSplitView with sidebar-driven detail routing:
  - `.disk` => disk content,
  - `.apps` => app uninstaller,
  - `.history` => trash history,
  - `.suggestion(category)` => suggestions detail.
- Toolbar:
  - prominent scan button,
  - view mode picker,
  - access mode toggle,
  - delete selected action,
  - disk free-space status bar.
- Use monospaced digits for size values and ByteCountFormatter `.file`.

PromptDev documentation deliverables:
Create and cross-link:
- README.md (project + PromptDev overview),
- PROMPT-DEV.md (concept mapping + why this repo pairs with the business-site narrative),
- promptdev/00-index.md
- promptdev/01-app-analysis.md
- promptdev/02-prompt-tldrs.md
- promptdev/03-prompt-chain.md
- promptdev/04-dependency-graph.md
- promptdev/05-conventions.md
- promptdev/06-golden-first-prompt.md (this file)

Doc quality requirement:
- Ensure promptdev stats reflect actual generated source counts/size; do not hardcode stale numbers.

Final acceptance gates:
1) `xcodebuild -scheme DiskCleaner -configuration Debug build` succeeds.
2) All source files are registered in pbxproj groups/build phases.
3) All navigation paths and sheets are wired and compile.
4) No placeholder TODO stubs in core features.
5) Provide a concise final report:
   - files created/updated,
   - feature checklist,
   - build result,
   - any intentional deviations.
```

## Notes

- This prompt is intentionally dense and implementation-specific.
- For higher reliability, pair it with `promptdev/05-conventions.md` as system-level context in the agent.
- If one-shot generation drifts, fall back to `promptdev/03-prompt-chain.md` for stepwise execution.
