# Coding Conventions

Rules and patterns that an LLM agent must follow when reproducing this codebase. Include these as system-level context or preamble to each prompt.

---

## Swift & SwiftUI Conventions

### State Management
- Use `@Observable` (Observation framework), NOT `ObservableObject`/`@Published`
- Central coordinator pattern: `AppViewModel` owns all sub-ViewModels and services
- Inject via `.environment()` on the root view, read via `@Environment(AppViewModel.self)`
- For bindings in view body: `@Bindable var appVM = appVM`
- For nested @Observable: create separate `@Bindable var nested = appVM.nestedVM`

### Concurrency
- Services are **actors** — thread-safe without manual locking
- Async work via `Task { }` blocks in ViewModels
- UI updates via `await MainActor.run { }` inside Tasks
- Progress callbacks typed as `@Sendable @escaping`
- Cancellation via `try Task.checkCancellation()` in loops
- No Combine — pure async/await

### Naming
- ViewModels: `{Feature}ViewModel` (@Observable final class)
- Services: `{Feature}Engine` or `{Feature}Service` (actor)
- Views: descriptive name, no "View" suffix on container views (exception: existing names)
- Enums: PascalCase cases, rawValue for display strings

### Formatting
- Human-readable sizes: `ByteCountFormatter.string(fromByteCount:countStyle: .file)` everywhere
- Monospaced digits for sizes: `.font(.caption.monospacedDigit())`
- SF Symbols for all icons — no custom assets
- Color coding: `.blue` (normal), `.orange` (warning/data), `.red` (danger/delete), `.green` (safe)

### File Organization
- One primary type per file (enum + struct combos OK if tightly coupled)
- Extensions in the same file as the type
- MARK comments for sections in larger files: `// MARK: - Section`

---

## Architecture Rules

### MVVM Boundaries
- **Models**: Plain types (struct/class/enum), no UI imports, no service dependencies
- **Services**: Actors, import Foundation/AppKit as needed, no SwiftUI, no ViewModel refs
- **ViewModels**: @Observable classes, own services, expose state to views, contain business logic
- **Views**: SwiftUI structs, read from ViewModels via @Environment, minimal logic

### Navigation
- `NavigationSplitView` with sidebar + detail
- Sidebar selection drives detail content via `switch` on `SidebarItem`
- No NavigationStack/NavigationLink — detail is computed from selection

### Deletion Pattern
- Always use `FileManager.trashItem` (move to Trash, undoable)
- Never use `removeItem` (permanent delete)
- Always show confirmation sheet before trashing
- Confirmation lists all items with sizes and total
- Reuse `DeletionService` actor across features

### File System Access
- Use `totalFileAllocatedSize` for accurate disk usage (not `fileSize`)
- Skip hidden files: `.skipsHiddenFiles` option
- Skip symlinks to prevent loops and double-counting
- Handle permission denied gracefully (mark node, don't crash)
- Check Full Disk Access before allowing full disk scan

---

## UI Patterns

### Sidebar
- Sections: Disk, Applications, Smart Suggestions, Total
- Each item tagged with `SidebarItem` enum case
- Size/count badges in capsule backgrounds

### Detail Views
- Header: icon + title + metadata + primary action
- Cards: equal-width cards in HStack for key metrics
- Lists: grouped by category with section headers
- Sheets: 450pt wide, scrollable item list (maxHeight 200), Cancel + Action buttons

### Toolbar
- Scan button (navigation placement)
- Primary actions (view toggle, access mode, contextual delete)
- Status (disk space bar)

### Colors & Tinting
- Button tint by state (blue=default, orange=scanning, green=complete, red=danger)
- Risk levels: green (safe), orange (moderate)
- Size bars: red (>50%), orange (>20%), blue (normal)
- File categories: blue/green/orange/purple/gray/cyan/brown for treemap

---

## Project Structure Rules

### Xcode Project
- All Swift files must be in pbxproj: PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase
- Use consistent ID format: `A1...` for build files, `A2...` for file refs, `A5...` for groups
- Groups must have `path` matching directory name
- New view subdirectories (Apps, TreeView, etc.) need their own PBXGroup

### Target Settings
- macOS 14.0 deployment target
- Swift 5.9
- Strict concurrency: complete
- Hardened runtime enabled
- No external dependencies — pure Apple frameworks only
