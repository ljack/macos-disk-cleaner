# Session 1: Initial Mega-Prompt (Abandoned)
**Date:** 2026-02-15 08:12 UTC
**Conversation:** `3fd82bb9-0f77-46e2-8042-ffc1d4284997`

## Commits
*None -- conversation was abandoned before any code was generated.*

## Prompts

### Prompt 1
> You are my senior macOS engineer. Build a native macOS app in Swift using Xcode.
>
> APP: "SpaceHound" -- a disk space analyzer + manager that shows where disk space went and lets users safely reclaim it.
>
> HARD REQUIREMENTS
> - Platform: macOS 14+.
> - Tech: Swift 5.9+, SwiftUI for UI. Use AppKit only when necessary (e.g., NSOpenPanel, reveal in Finder).
> - Distribution: assume sandboxed app (Mac App Store compatible). Therefore:
>   - Only scan the user's Home directory and any additional folders the user explicitly selects via NSOpenPanel.
>   - Persist user-selected folders using security-scoped bookmarks.
> - Must run fast and not freeze UI. Use Swift Concurrency (async/await, TaskGroup) and background work.
> - All delete actions must be SAFE:
>   - Default action is "Move to Trash" (FileManager trashItem).
>   - Always show the exact file path(s) and total size before performing actions.
>   - Never offer deletion of protected/system locations.
> - No external dependencies for MVP (no CocoaPods/SPM packages).
>
> MVP FEATURES (deliver these first)
> 1) "Select Folders" screen:
>    - Button to add folders (NSOpenPanel)
>    - List selected folders with remove button
>    - "Scan" button
> 2) Scanner:
>    - Recursively compute allocated size per folder (prefer allocated bytes when possible).
>    - Treat packages (.app, .photoslibrary, etc.) as single items unless expanded (MVP: treat as single).
>    - Exclude symlinks to avoid loops.
>    - Provide progress updates + cancel scan.
> 3) Results UI:
>    - Left: list of top folders/files by size (sortable).
>    - Right inspector: path, size, last modified, "Reveal in Finder", "Move to Trash".
>    - Filter: minimum size slider (e.g., 50MB+).
> 4) Snapshot history (simple):
>    - Store scan runs in a local JSON or SQLite-free lightweight store (UserDefaults or local file).
>    - Show "Changes since last scan" for each selected root (delta by path).
>    - If you can't do full delta reliably in MVP, implement root-level delta only and label it clearly.
>
> DELIVERABLES
> A) Start with a clear implementation plan:
>    - milestones, file/module structure, key classes/actors, and data models.
> B) Then generate the full code for an Xcode project (MVP):
>    - Swift files with correct imports, no placeholders.
>    - A minimal but clean SwiftUI UI.
>    - A scanning engine using async/await with cancellation and progress.
>    - Bookmark persistence for selected folders.
>    - Safe "move to trash" with confirmation dialog.
> C) Provide exact Xcode steps to create the project and where to paste each file.
> D) Add a short "next improvements" list (duplicates, treemap, FSEvents, Spotlight, etc.).
>
> CODING RULES
> - Use MVVM.
> - Keep state in an ObservableObject/StateObject.
> - Use actors for thread-safe aggregation during scanning.
> - Make results deterministic and testable.
> - Use ByteCountFormatter for sizes.
> - When you output code, output it in separate fenced code blocks per file, titled with the filename.
> - Do not omit any required imports or types.
>
> Now do (A) then (B) then (C) then (D).

*Note: This monolithic prompt was interrupted almost immediately. The conversation was abandoned and restarted with a collaborative planning approach in Session 2.*
