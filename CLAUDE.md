# CLAUDE.md

## Project Overview

DiskCleaner is a native macOS disk space analyzer and cleaner sold on the Apple App Store. It scans user-selected directories, visualizes disk usage via a treemap and file tree, detects known space wasters (Xcode DerivedData, caches, node_modules, etc.), and supports app uninstallation with associated file cleanup.

## Toolchain

- **Swift 6.2.3** (strict concurrency enabled — `SWIFT_VERSION = 6`)
- **Xcode 26.2** (Build 17C52)
- **Deployment target:** macOS 14.0
- **Architecture:** arm64 (Apple Silicon)

## App Store / Sandbox Constraints

This app ships through the Mac App Store. All code changes must respect:

- **App Sandbox is ON** — entitlements: `com.apple.security.app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`
- Filesystem access is limited to user-granted directories via `NSOpenPanel` + security-scoped bookmarks
- **Use `NSWorkspace.shared.recycle()` for Trash operations** — never `FileManager.trashItem()`, which fails under sandbox for paths outside the user-selected scope
- Never request Full Disk Access or TCC-protected paths programmatically
- `PrivacyInfo.xcprivacy` declares: FileTimestamp (C617.1), DiskSpace (E174.1), UserDefaults (CA92.1) — update if new required-reason APIs are used
- No network calls, no tracking, no collected data

## Architecture

Single-window SwiftUI app using `@Observable` ViewModels (not ObservableObject/Combine).

```
DiskCleaner/
├── DiskCleanerApp.swift          # @main, creates AppViewModel
├── Models/                       # Value types: FileNode, ScanResult, SpaceWaster, InstalledApp, etc.
├── Services/                     # Business logic actors/classes
│   ├── ScanningEngine.swift      # Recursive filesystem scanner (actor)
│   ├── SuggestionsEngine.swift   # In-memory tree analysis for known wasters (actor)
│   ├── DeletionService.swift     # NSWorkspace.recycle wrapper (actor, protocol: DeletionServiceProtocol)
│   ├── DiskSpaceHistory.swift    # Disk space snapshots + DirectoryExclusionStore
│   ├── BookmarkService.swift     # Security-scoped bookmark persistence
│   └── AppDiscoveryEngine.swift  # /Applications scanner
├── ViewModels/                   # @MainActor @Observable classes
│   ├── AppViewModel.swift        # Central coordinator — owns all other VMs and services
│   ├── ScanViewModel.swift       # Scan state machine (ScanStatus enum)
│   ├── SuggestionsViewModel.swift
│   └── AppUninstallerViewModel.swift
├── Views/                        # SwiftUI views (Shared/, TreeView/, TreemapView/, Apps/, Suggestions/)
├── Algorithms/
│   └── SquarifiedTreemap.swift   # Pure layout algorithm
└── Utilities/
    ├── FileTypeClassifier.swift  # Extension → category mapping
    └── URLExtensions.swift       # fileSize, isDirectory, systemIcon
```

**Key patterns:**
- `FileNode` is a reference-type tree (`final class`) for efficient large tree handling
- ViewModels use `@MainActor @Observable` — not `ObservableObject`
- Services that do I/O are `actor`-isolated
- `DeletionServiceProtocol` enables mock injection for testing
- Environment-based DI: `AppViewModel` is passed via `.environment(appVM)`

## Build & Test

```bash
# Build
xcodebuild build -scheme DiskCleaner -destination 'platform=macOS'

# Run all tests (102 tests)
xcodebuild test -scheme DiskCleaner -destination 'platform=macOS'
```

The test target is `DiskCleanerTests` with `@testable import DiskCleaner`. Tests use:
- `FileNodeBuilder` helper for building in-memory trees
- `MockDeletionService` conforming to `DeletionServiceProtocol`
- Isolated `UserDefaults` cleanup in setUp for store tests

## Swift 6 Concurrency Rules

This project uses **Swift 6 strict concurrency**. When writing code:

- All closures crossing isolation boundaries must be `@Sendable`
- `@MainActor` types need `override func setUp() async throws` in tests (not sync `setUp()`)
- Actor methods that accept closures need those closures typed as `@Sendable`
- Use `any ProtocolName` for existential protocol types (e.g., `any DeletionServiceProtocol`)

## Common Pitfalls

- **Sandbox + Trash:** `FileManager.trashItem()` fails for paths outside user-granted scope. Always use `NSWorkspace.shared.recycle()` via `DeletionService`.
- **FileNode is a class:** Reference semantics — mutations propagate through the tree. `parent` is `weak`.
- **Size recalculation:** After modifying `isTrashed`/`isHidden` flags, call `recalculateSizeUpward()` on the parent to propagate changes.
- **UserDefaults keys:** `diskSpaceHistory`, `directoryExclusionRules`, `trashHistory`, `autoScanEnabled`, `autoScanDelay` — don't collide with these.
