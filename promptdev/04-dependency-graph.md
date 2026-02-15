# Dependency Graph

## File Dependencies

Arrows show "depends on" relationships. Files at the top have no dependencies.

```
Layer 0 — No dependencies (pure models + utilities)
├── DiskAccessMode.swift
├── FileTypeClassifier.swift
└── URLExtensions.swift

Layer 1 — Depends on Layer 0
├── FileNode.swift               → (standalone, uses Foundation)
├── ScanResult.swift              → FileNode, DiskAccessMode
├── SpaceWaster.swift             → (standalone)
└── InstalledApp.swift            → (standalone, uses AppKit for NSImage)

Layer 2 — Services (depend on models)
├── ScanningEngine.swift          → FileNode, ScanProgress (defined within)
├── SuggestionsEngine.swift       → SpaceWaster, FileNode
├── DeletionService.swift         → (standalone, uses AppKit)
├── PermissionService.swift       → (standalone, uses AppKit)
└── AppDiscoveryEngine.swift      → InstalledApp, URLExtensions

Layer 3 — ViewModels (depend on models + services)
├── ScanViewModel.swift           → ScanningEngine, ScanResult, DiskAccessMode
├── SuggestionsViewModel.swift    → SuggestionsEngine, SpaceWaster, FileNode
└── AppUninstallerViewModel.swift → AppDiscoveryEngine, InstalledApp, DeletionService

Layer 4 — Coordinator ViewModel
└── AppViewModel.swift            → ScanViewModel, SuggestionsViewModel, AppUninstallerViewModel,
                                    DeletionService, PermissionService, DiskAccessMode,
                                    FileNode, SpaceWasterCategory, ViewMode, SidebarItem

Layer 5 — Algorithm
└── SquarifiedTreemap.swift       → FileNode, FileTypeClassifier

Layer 6 — Views (depend on ViewModels via @Environment)
├── ScanButtonView.swift          → AppViewModel (scanVM.status)
├── ProgressOverlayView.swift     → AppViewModel (scanVM.progress)
├── ConfirmationSheet.swift       → AppViewModel (selectedNodes, deletion state)
├── FileTreeView.swift            → AppViewModel, FileNode
├── FileTreeRowView.swift         → AppViewModel, FileNode, FileTypeClassifier
├── TreemapCanvasView.swift       → AppViewModel, FileNode, SquarifiedTreemap, FileTypeClassifier
├── TreemapContainerView.swift    → AppViewModel, FileNode, TreemapCanvasView, FileTypeCategory
├── SuggestionsListView.swift     → AppViewModel, SpaceWasterCategory
├── AppListView.swift             → AppViewModel, AppDetailView, AppRowView
├── AppDetailView.swift           → AppViewModel, InstalledApp, SizeCardView
├── UninstallConfirmationSheet.swift → AppViewModel, InstalledApp
├── SidebarView.swift             → AppViewModel, SpaceWasterCategory, SidebarItem
├── ToolbarView.swift             → AppViewModel, ScanButtonView, ViewMode
└── MainWindowView.swift          → AppViewModel, SidebarView, ToolbarView, all detail views

Layer 7 — App Entry
└── DiskCleanerApp.swift          → AppViewModel, MainWindowView
```

## Build Order (Minimal Recompilation)

For incremental builds, modify files in this order:

1. Models (no recompilation cascade)
2. Utilities (only views that use them recompile)
3. Services (only their VMs recompile)
4. ViewModels (views recompile)
5. Views (leaf nodes, no cascade)
6. App entry (only itself)

## Prompt-to-File Mapping

| Prompt | Creates | Modifies |
|--------|---------|----------|
| P1 | DiskCleanerApp.swift, project structure | — |
| P2 | FileNode, ScanResult, DiskAccessMode | — |
| P3 | ScanningEngine, ScanViewModel, URLExtensions | — |
| P4 | AppViewModel, PermissionService, MainWindowView, SidebarView, ToolbarView, ScanButtonView | DiskCleanerApp |
| P5 | FileTypeClassifier, FileTreeView, FileTreeRowView, ProgressOverlayView | — |
| P6 | SquarifiedTreemap, TreemapCanvasView, TreemapContainerView | AppViewModel |
| P7 | SpaceWaster, SuggestionsEngine, SuggestionsViewModel, SuggestionsListView | AppViewModel, SidebarView, MainWindowView |
| P8 | DeletionService, ConfirmationSheet | AppViewModel, MainWindowView |
| P9 | InstalledApp, AppDiscoveryEngine, AppUninstallerViewModel, AppListView, AppDetailView, UninstallConfirmationSheet | AppViewModel, SidebarView, MainWindowView |
| P10 | — | project.pbxproj |
