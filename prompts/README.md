# DiskCleaner -- Development Prompt Archive

Complete chronological archive of every user prompt from the Claude Code conversations used to build DiskCleaner, a native macOS disk space analyzer and cleaner.

## Development Story

DiskCleaner was built from zero to signed-and-notarized release in a single 17-hour session on February 15-16, 2026. One developer, one Claude Code agent (Opus), 81 prompts, 25 commits.

### How it started
The first attempt was a 70-line mega-prompt specifying every detail upfront -- sandboxed, MVVM, security-scoped bookmarks, snapshot history. It was abandoned within minutes. The second attempt was one sentence: *"we're building macos native app that allows user to figure out where disk space is used and clean things up. create a plan. ask questions if unsure."* That collaborative approach produced the architecture plan used for the rest of development.

### What was built
A full native macOS 14+ SwiftUI app (4,804 lines of Swift across 39 files):
- **Disk scanning** -- async/await actor-based recursive scanner with progress, cancellation, TCC-aware permission flow
- **Visualization** -- squarified treemap (Canvas-rendered) + sortable file tree with size-sorted navigation
- **Smart suggestions** -- node_modules detection, large file identification, cache cleanup recommendations
- **App uninstaller** -- scans /Applications, finds associated ~/Library files, bulk uninstall to trash
- **Disk space history** -- time-bucketed compaction with Swift Charts popover
- **Hidden items + trash history** -- hide nodes from results, restore from trash, dimmed trashed nodes in tree
- **CI/CD** -- GitHub Actions for DMG build, tag-based releases, code signing, notarization

### How it evolved
Development followed a pattern: **plan in one session, implement in the next**. Features accumulated organically -- each session ended with planning the next feature. The biggest detour was the Swift 6 migration (Session 12, 27 prompts): the app was built in Swift 5 mode, then migrated, requiring a deep concurrency audit with 20+ targeted fix prompts.

### What the optimized rebuild looks like
See **[OPTIMIZED-REBUILD.md](OPTIMIZED-REBUILD.md)** -- a hypothetical 8-prompt chain that rebuilds the same app directly in Swift 6, eliminating migration overhead, retry loops, side quests, and operational prompts. Reduces 81 prompts to 8.

---

## Timeline

All development occurred on a single day: **February 15-16, 2026** (~17 hours, 08:12 - 01:00 UTC).

| Session | Time (UTC) | Prompts | Theme | Commits |
|---|---|---|---|---|
| [01](01-initial-mega-prompt.md) | 08:12 | 1 | Initial mega-prompt (abandoned) | -- |
| [02](02-planning-session.md) | 08:16 | 1 | Collaborative planning pivot | -- |
| [03](03-core-implementation.md) | 08:25 | 7 | Full app build: models, views, scan, treemap, suggestions, deletion | `e6bbfbb` |
| [04](04-uninstaller-and-features.md) | 09:33 | 11 | App uninstaller, PromptOps, auto-scan, trash history | `a8371ac` `fc2c4bb` `086ee4a` |
| [05](05-trashed-files-permissions.md) | 12:17 | 2 | Trashed file marking, permission handling planning | `f125de6` `125629f` `eae2b9d` |
| [06](06-non-blocking-permissions.md) | 12:32 | 3 | TCC-aware scanning, hide/unhide planning | (see 05) |
| [07](07-hidden-items.md) | 12:55 | 3 | Hide/unhide feature, double-click planning | `e37ce9a` `a835dfb` |
| [08](08-navigation-and-history.md) | 13:11 | 6 | Double-click, node_modules fix, disk space history | `1f20c0b` `a78dce1` |
| [09](09-disk-space-history.md) | 13:54 | 3 | Disk free history implementation, post-scan banner planning | -- |
| [10](10-banner-and-swift6-planning.md) | 17:43 | 5 | Permissions banner, tree re-sort, Swift 6 planning | `9e1e128` `25a1896` `c18eccf` `16366e5` `fcc11ac` |
| [11](11-empty.md) | 18:44 | 0 | (empty conversation) | -- |
| [12](12-swift6-migration.md) | 18:44 | 27 | Swift 6 migration, deep concurrency audit, v0.9.0 release | `ae2474a` `c346a5f` |
| [13](13-signing-notarization.md) | 22:04 | 13 | Apple Developer enrollment, code signing, notarization CI | `12324ac` `e4879d5` `a61b62f` `5505ecc` `aa1c46b` `09889de` `fdf8d6e` |
| **Total** | | **81** | | **25 commits** |

## Commit Index

| Commit | Message | Session |
|---|---|---|
| `e6bbfbb` | Initial commit: macOS Disk Cleaner app | 03 |
| `a8371ac` | Add app uninstaller feature and promptdev docs | 04 |
| `fc2c4bb` | Add public docs and CI secret scanning | 04 |
| `086ee4a` | Add trash history workflow and golden PromptDev prompt | 04 |
| `f125de6` | Add TCC-aware scan flow and directory permission state | 05-06 |
| `125629f` | Add permissions center UI and tree-level access actions | 05-06 |
| `eae2b9d` | Fix TCC directory detection and pre-enumeration interception | 05-06 |
| `e37ce9a` | Add GitHub DMG build and tag release pipelines | 07 |
| `a835dfb` | Add hidden items workflow across disk views | 07 |
| `1f20c0b` | Improve disk navigation actions and live space refresh | 08 |
| `a78dce1` | Add disk space history popover in toolbar | 08 |
| `9e1e128` | Fix Swift concurrency error in uninstall completion callback | 10 |
| `25a1896` | Fix CI concurrency capture in scan progress callback | 10 |
| `c18eccf` | Run CI release workflows on Xcode 26.2 | 10 |
| `16366e5` | Refactor scan progress updates to main-actor isolation | 10 |
| `fcc11ac` | Add directory exclusion rules, post-scan permissions banner, and tree re-sort | 10 |
| `ae2474a` | Migrate to Swift 6 language mode with concurrency fixes | 12 |
| `c346a5f` | Bump version to 0.9.0 and add download link to README | 12 |
| `12324ac` | Add code signing and notarization to release pipeline | 13 |
| `e4879d5` | Fix workflow: use job-level env for secrets conditionals | 13 |
| `a61b62f` | Fix base64 decode in import_certificate.sh for macOS runners | 13 |
| `5505ecc` | Debug certificate import: add file size/header logging and -f pkcs12 | 13 |
| `aa1c46b` | Remove debug logging from import_certificate.sh | 13 |
| `09889de` | Update README download link to v0.9.1 and add releases page link | 13 |
| `fdf8d6e` | Update README screenshot with current scanning view | 13 |

## Stats

- **Conversations:** 13 (12 with content, 1 empty)
- **Substantive prompts:** ~81
- **Git commits:** 25
- **Development time:** ~17 hours
- **Developer:** Single developer + Claude Code (Opus)
- **Swift source:** 4,804 lines across 39 files
- **CI/scripts:** 4 shell scripts + 3 GitHub Actions workflows
