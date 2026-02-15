# Optimized Rebuild: DiskCleaner in 8 Prompts

Hypothetical prompt chain to rebuild DiskCleaner from scratch, incorporating all lessons learned. Targets Swift 6 from the start, batches related features, eliminates migration overhead, skips retry loops and side quests.

## Analysis: Where the 81 prompts went

| Category | Prompts | Examples |
|---|---|---|
| Feature implementation | 22 | Core build, uninstaller, permissions, hidden items, disk history |
| Bug fixes (preventable) | 5 | "hide didn't work in list", "node_modules clean does nothing", TCC detection wrong |
| Swift 6 migration + audit | 22 | Migration, concurrency audit, 15 individual targeted fixes |
| Planning (merged into impl) | 8 | Plan sessions that preceded implementation sessions |
| Operational (git, CI, builds) | 8 | "git add and push", "check build status", "download DMG" |
| Interactive debugging loops | 7 | Certificate import retries (4 commits for one fix), signing setup Q&A |
| Informational / irrelevant | 6 | "check credits", "how is disk free calculated", "claudex is working" |
| Side quests | 1 | PromptOps analysis |
| Empty / crashed | 2 | Empty conversation, "Claude was hung" |

### Key optimizations

1. **Swift 6 from day one** eliminates 22 prompts (the entire migration + audit cycle)
2. **Batching related features** merges 8 planning-then-implementing pairs into single prompts
3. **Specifying edge cases upfront** prevents 5 bug-fix prompts
4. **Pre-configured CI secrets** eliminates the 7-prompt interactive certificate setup loop
5. **Skipping non-app work** drops PromptOps, credit checks, informational questions

**Result: 81 prompts → 8 prompts (90% reduction)**

---

## Prompt 1: Plan

```
We're building a native macOS disk space analyzer and cleaner app called "DiskCleaner".

Target: macOS 14+ (Sonoma), Swift 6 language mode, SwiftUI.
Non-sandboxed (needs filesystem access). No external dependencies.

Create an implementation plan. Key requirements:
- MVVM with @Observable ViewModels, actor-based services
- Async/await scanning engine with cancellation and progress
- Squarified treemap visualization using Canvas (not SwiftUI views)
- Smart suggestions (node_modules, caches, large files)
- Safe deletion (move to trash only, confirmation dialogs)
- Full Disk Access detection and guidance

Swift 6 concurrency rules from the start:
- @MainActor on all ViewModels
- Sendable conformance on all model structs
- FileNode as @unchecked Sendable (class with MainActor-only mutation)
- No fire-and-forget Tasks -- store and cancel properly
- No redundant MainActor.run inside @MainActor methods
- @Sendable on all escaping closures

Ask questions if unsure.
```

*Replaces: Sessions 1-2 (2 prompts). Eliminates the abandoned mega-prompt entirely and bakes Swift 6 requirements into the plan upfront.*

---

## Prompt 2: Core App

```
Implement the plan.

Additional UX requirements not in the plan:
- Prominent "Scan" button with status states: needsScan, scanning (with progress),
  completed (with timestamp), expired (scan older than 1 hour). Use SF Symbols.
- Design and generate an app icon (magnifying glass + disk theme, blue/purple gradient).
  Generate all required sizes for AppIcon.appiconset.
- Include AccentColor in asset catalog.
- Treemap: click to zoom into directory, double-click file to reveal in Finder.
- File tree: double-click to reveal in Finder. Sortable by size.
- Toolbar: disk free space indicator with click-to-refresh.

Concurrency requirements:
- ScanningEngine as an actor. Progress reported via @MainActor callback, not closure capture.
- SuggestionsEngine: run tree walks on MainActor (fast enough for typical trees).
  Store detectTask, cancel previous before starting new. Check Task.isCancelled in loops.
- ScanViewModel.startScan: use [weak self] in stored Task to avoid retain cycle.

Initialize git repo and make first commit when done.
```

*Replaces: Session 3, prompts 1-6 (6 prompts). Prevents the scan button UX issue, AccentColor bug, and bakes concurrency patterns that were discovered 10 hours later during the Swift 6 audit.*

---

## Prompt 3: Uninstaller, Live Updates, Auto-Scan

```
New features in one batch:

1. APP UNINSTALLER
   - Scan /Applications for .app bundles
   - Read Info.plist for bundle ID
   - Search ~/Library (Caches, Preferences, Application Support, Containers,
     Logs, Saved Application State, HTTPStorageManager, WebKit) for associated files
   - Sortable/searchable app list with icon, name, total size
   - Detail view with breakdown by location
   - Uninstall = trash app + all associated files with confirmation sheet
   - Also allow uninstalling directly from treemap/file tree right-click context menu
   - Callback closure must be explicitly @MainActor @Sendable

2. SCAN RESULT LIVE UPDATES
   - After any deletion (file, app, suggestion), update the scan tree in-place
   - Remove trashed nodes from parent, recalculate parent sizes up the tree
   - Re-detect suggestions after deletion

3. AUTO-SCAN
   - Default: auto-scan 30 seconds after app launch with countdown + abort button
   - Configurable in settings: enabled/disabled, delay in seconds
   - Show scan timestamp in UI ("Last scan: 5 minutes ago")
   - Advertise auto-scan near the Scan button when not configured

4. APP ICON IN UI
   - Show the app icon somewhere visible in the main window (toolbar or sidebar header)
```

*Replaces: Session 4, prompts 1, 6-11 (7 prompts). Batches all the feature requests that were made one-by-one. Prevents the "node_modules clean doesn't do anything" bug by requiring live updates upfront.*

---

## Prompt 4: Trash History with Trashed Marking

```
Add trash management features:

1. TRASH HISTORY VIEW
   - Track every item moved to trash: original path, size, timestamp, trash URL
   - Sidebar section "Trash History" with list of trashed items
   - "Restore" button per item (FileManager.moveItem from trash URL back to original)
   - Clear history option

2. TRASHED NODE MARKING IN TREE
   - After trashing a file/folder, keep the node visible in tree and treemap
   - Dimmed appearance (0.5 opacity) with strikethrough text
   - "Restore" button inline on each trashed node
   - Recalculate parent sizes excluding trashed children
   - "Show in Tree" link from Trash History navigates to the node in tree view
```

*Replaces: Session 4 prompt 11 + Session 5 prompt 1 (2 prompts). Merges the two related features that were split across sessions.*

---

## Prompt 5: Permissions, Hidden Items, Post-Scan Banner

```
Three related features for managing scan completeness:

1. TCC-AWARE NON-BLOCKING SCAN
   - Detect TCC-protected directories (Desktop, Documents, Downloads) BEFORE
     attempting enumeration. Use a test-read approach, not hardcoded paths
     (user may have custom folder names or moved standard folders).
   - Create placeholder nodes for restricted directories (show lock icon + size "Unknown")
   - Continue scanning non-restricted directories without blocking
   - Track permission state per directory: pending / denied / granted

2. PERMISSIONS UI
   - Sidebar section "Permissions" with list of restricted directories
   - "Grant Access" button per directory triggers system permission dialog
   - "Grant All Pending" button with small delay between each (and proper cancellation --
     do NOT use try? to swallow CancellationError from Task.sleep)
   - After granting: scan the newly-accessible subtree and merge into existing tree
   - Re-sort the entire tree after merging new subtrees (by size descending)

3. POST-SCAN PERMISSIONS BANNER
   - After scan completes, if any directories were restricted, show dismissible
     inline banner at top of disk content area
   - "N directories could not be scanned. Review permissions." with "Review" button
   - "Review" navigates to Permissions sidebar view
   - Auto-dismiss on next scan

4. HIDE/UNHIDE ITEMS
   - Right-click context menu "Hide from Results" on any tree/treemap node
   - Hidden items filtered from tree view, treemap, and suggestions
   - Recalculate parent display sizes excluding hidden children
   - Sidebar section "Hidden Items" with "Show" button per item and "Show All"
   - New scan clears all hidden state

Concurrency note for rescanDirectory():
- Store rescanTask, cancel previous before starting new
- Use identity-based cleanup: if rescanTask === task { rescanTask = nil }
- Add cancellation checks after awaits
```

*Replaces: Sessions 5-7, 9 prompt 3, 10 prompts 1-2 (11 prompts across 5 sessions). Consolidates the entire permissions/hidden/banner feature set that was developed iteratively with bugs along the way. Includes the TCC detection fix and rescan concurrency fix that were discovered later.*

---

## Prompt 6: Navigation and Disk Space History

```
Two feature areas:

1. NAVIGATION IMPROVEMENTS
   - Double-click file in tree view: reveal in Finder (NSWorkspace.shared.activateFileViewerSelecting)
   - Double-click directory in treemap: zoom in (existing behavior, keep it)
   - From Smart Suggestions list, add "Show in Tree" button that navigates to
     the relevant node in the file tree and selects it
   - Refresh disk free space indicator on: scan complete, deletion, restore,
     permission grant, app uninstall

2. DISK FREE SPACE HISTORY
   - Model: DiskSpaceSnapshot (date, freeBytes, totalBytes)
   - Record a snapshot every time refreshDiskSpace() runs
   - Persist to UserDefaults (JSON encoded array)
   - Time-bucket compaction on load:
     - Last 24h: keep all (1 per event)
     - Last 7d: keep 1 per hour
     - Last 30d: keep 1 per day
     - Last 365d: keep 1 per week
     - Older: keep 1 per year
   - UI: popover from disk free toolbar icon
   - Swift Charts AreaMark showing free space over time
   - Dynamic X-axis based on data range
```

*Replaces: Sessions 8-9 (9 prompts). Eliminates the "how is disk free calculated?" informational prompt and the "node_modules clean doesn't work" bug fix (already handled in Prompt 3).*

---

## Prompt 7: CI/CD, Code Signing, Notarization

```
Set up GitHub Actions CI/CD with code signing and notarization.

IMPORTANT: All secrets are already configured in GitHub repo settings:
- CERTIFICATE_BASE64 (Developer ID Application certificate, base64-encoded .p12)
- CERTIFICATE_PASSWORD
- APPLE_ID
- APPLE_APP_PASSWORD (app-specific password from appleid.apple.com)
- TEAM_ID

1. SCRIPTS (scripts/ci/)
   - build_release_app.sh: xcodebuild archive + export with Developer ID signing
   - package_dmg.sh: create DMG with hdiutil, codesign the DMG itself
   - import_certificate.sh: decode base64 cert, create temp keychain, import with
     `security import` using `-f pkcs12` flag (required on macOS runners).
     Use `base64 -D` (macOS) not `base64 -d` (Linux).
   - notarize.sh: submit with xcrun notarytool, staple with xcrun stapler

2. WORKFLOWS
   - build-master-dmg.yml: build on push to master, upload DMG as artifact.
     Use macos-latest, Xcode 26.2 (xcode-select).
   - release-on-tag.yml: on tag push v*, build + sign + notarize + create
     GitHub release with DMG attached.
     Use job-level env for secrets (not step-level, because `if:` conditionals
     on steps can't read step-level env).
   - gitleaks.yml: secret scanning on push

3. .gitignore should exclude *.p12, *.keychain-db, build/
```

*Replaces: Session 7 CI prompts + Session 13 prompts 1-12 (14 prompts). Eliminates the entire interactive certificate setup Q&A loop and the 4-commit debug cycle for import_certificate.sh. All known pitfalls (base64 -D vs -d, -f pkcs12, job-level env) are specified upfront.*

---

## Prompt 8: Release and README

```
Prepare for release:

1. Set version to 0.9.0 in project.pbxproj (MARKETING_VERSION)
2. Create comprehensive README.md:
   - App name, one-line description, screenshot (from screesnhots/first-launch.png)
   - Feature list
   - Download link pointing to GitHub releases page: https://github.com/<owner>/<repo>/releases
   - Direct DMG download link for current version
   - Build from source instructions
   - Requirements: macOS 14+, Full Disk Access recommended
3. Tag v0.9.0 and push to trigger release workflow
```

*Replaces: Session 12 prompts 24-26 + Session 13 prompts 13-14 (5 prompts). Combines version bump, README, and release into one action.*

---

## Comparison

| | Original | Optimized | Savings |
|---|---|---|---|
| Prompts | 81 | 8 | 90% |
| Sessions | 13 | 8 | 38% |
| Planning-only sessions | 3 | 1 | 67% |
| Bug fix prompts | 5 | 0 | 100% |
| Swift migration prompts | 22 | 0 | 100% |
| CI debug/retry prompts | 7 | 0 | 100% |
| Operational prompts | 8 | 1 | 88% |

### What makes this possible

The optimized chain is not just "fewer prompts" -- it encodes **knowledge that was discovered during development**:

1. **Concurrency patterns** -- The original development discovered retain cycles, stale task overwrites, redundant MainActor.run, fire-and-forget Tasks, and cancellation swallowing over 20+ prompts. The optimized chain specifies correct patterns upfront.

2. **Platform quirks** -- `base64 -D` (not `-d`) on macOS, `-f pkcs12` for security import, job-level env for GitHub Actions conditionals. Each was a debug cycle in the original; each is a one-liner in the optimized prompt.

3. **Feature interactions** -- Hiding items didn't filter from the list view. Node deletion didn't update the tree. These are specified as requirements rather than discovered as bugs.

4. **Architecture decisions** -- Non-sandboxed (not sandboxed as Session 1 assumed), Canvas treemap (not SwiftUI views), @Observable (not ObservableObject), Swift 6 (not 5 then migrate).

### What this analysis does NOT optimize

- **User testing and iteration** -- Some prompts were the developer using the app and noticing things ("the UI looks beautiful!", "feature creep is starting to creep"). This organic discovery can't be pre-scripted.
- **Learning** -- The developer was new to Swift/SwiftUI. Questions like "how is disk free calculated?" served a learning purpose beyond the code.
- **Emergent features** -- Auto-scan, disk space history, and the permissions banner emerged from using the app. A rebuild might produce different features.
