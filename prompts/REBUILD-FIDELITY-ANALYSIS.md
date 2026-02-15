# Rebuild Fidelity Analysis

**Question:** If you run the 8 optimized prompts from [OPTIMIZED-REBUILD.md](OPTIMIZED-REBUILD.md), what's the probability the resulting app works as a drop-in replacement for the current DiskCleaner?

**Short answer:** ~2% as-is. ~50-65% with a compatibility appendix specifying exact identifiers, keys, and model shapes.

---

## Dimensions of "drop-in replacement"

| Dimension | What needs to match | Probability | Impact if wrong |
|---|---|---|---|
| Bundle identifier | `com.diskcleaner.app` exactly | ~5% | Fatal: macOS treats as different app |
| UserDefaults keys | 5 exact string keys | ~10% | Data loss: settings, history, exclusions |
| Persisted JSON schemas | 4 Codable structs field-for-field | ~10% | Data loss: crash or silent discard on decode |
| Feature completeness | All behaviors present | ~85% | Missing functionality |
| Concurrency correctness | No races, no leaks | ~80% | Subtle bugs under load |
| UI layout & feel | Same visual impression | ~25% | Looks different, confuses existing users |
| Exact string literals | ~100+ UI labels, messages | ~5% | Cosmetic differences everywhere |
| Color values | AccentColor RGB, category colors | ~15% | Different look |
| SF Symbol choices | ~60 specific symbol names | ~10% | Different iconography |

### Why bundle identifier is fatal

The bundle ID (`com.diskcleaner.app`) determines:
- Which UserDefaults domain the app reads/writes
- Which macOS permission grants (Full Disk Access, Files and Folders) apply
- Which Keychain items are accessible
- Whether macOS recognizes it as the "same app" in Dock, Launchpad, Spotlight

The optimized prompts say "called DiskCleaner" but never specify the bundle ID. An LLM might generate `com.example.DiskCleaner`, `com.jarkko.diskcleaner`, `dev.diskcleaner.app`, etc. Without an exact match, the rebuilt app is a **new app** from the OS perspective -- existing Full Disk Access grants won't apply, and the user must re-grant all permissions.

**Estimated probability of exact match: ~5%**

### Why UserDefaults keys matter

The app persists 5 keys:

| Key | Type | What's lost if wrong |
|---|---|---|
| `"autoScanEnabled"` | Bool | Setting resets to default |
| `"autoScanDelay"` | Int | Setting resets to default |
| `"trashHistory"` | JSON ([TrashedItem]) | All trash history lost, orphaned trash items |
| `"diskSpaceHistory"` | JSON ([DiskSpaceSnapshot]) | All disk space trend data lost |
| `"directoryExclusionRules"` | JSON ([ExcludedDirectoryRule]) | All exclusion rules lost |

The keys `autoScanEnabled` and `autoScanDelay` are somewhat conventional and have maybe ~40% chance each of matching. But `trashHistory`, `diskSpaceHistory`, and `directoryExclusionRules` are specific enough that alternatives are equally likely (`trashedItems`, `diskHistory`, `excludedDirectories`, etc.).

**Probability all 5 keys match: ~10%** (generous, assuming some correlation)

### Why JSON schema compatibility is critical

Even if the keys match, the Codable struct shapes must match field-for-field. Consider `TrashedItem`:

```swift
struct TrashedItem: Identifiable, Codable {
    let id: UUID
    let originalURL: URL
    let trashURL: URL
    let name: String
    let size: Int64
    let date: Date
    let source: TrashSource

    enum TrashSource: String, Codable {
        case fileTree = "File Tree"
        case suggestion = "Suggestion"
        case appUninstall = "App Uninstall"
    }
}
```

A rebuilt version might:
- Use `originalPath: String` instead of `originalURL: URL`
- Call the field `trashedDate` instead of `date`
- Use `deletionSource` instead of `source`
- Use lowercase enum raw values (`"fileTree"` instead of `"File Tree"`)
- Add or omit fields (`isRestored`, `fileType`, etc.)

Any of these differences causes `JSONDecoder` to fail, silently discarding all persisted data.

Four structs need to match: `TrashedItem` (7 fields + nested enum), `DiskSpaceSnapshot` (2 fields), `ExcludedDirectoryRule` (7 fields + nested enum), `ExclusionRuleScope` (3 cases with raw values).

**Probability all schemas match: ~10%**

### Why feature completeness is high but not certain

The optimized prompts are detailed. All major features are described. But some behaviors emerged from bug fixes and were never explicitly specified:

- Trash history capped at 200 items (`Array(trashHistory.prefix(200))`)
- Scan status thresholds: fresh < 5 min, aging 5-60 min, stale > 1 hour
- Auto-scan default delay: 3 seconds (the original prompt said 30 seconds but implementation used 3)
- `findNode(at:)` tree search method for "Show in Tree" navigation
- `recalculateSizeUpward()` propagation after any tree mutation
- `descendantCount` tracking on FileNode

These details are likely to be implemented *differently* but *functionally* -- the app would still work, but edge case behavior would differ.

**Probability of feature completeness: ~85%**

### Why UI would look different

The optimized prompts describe *what* the UI should contain, not *how* it should look. Unspecified details include:

- **Window size:** currently 1100x700
- **AccentColor:** light #3385D9, dark #59A6F2
- **Sidebar section ordering:** Disk Content, Smart Suggestions, App Uninstaller, Permissions, Hidden Items, Trash History, Settings
- **File type colors:** blue=code, green=media, orange=docs, purple=archives, gray=system, cyan=data, brown=directory
- **Treemap color palette and gradient behavior**
- **Scan button animation states and icon transitions**
- **Toolbar layout:** app icon position, disk free indicator, scan button placement
- **Context menu item ordering and labels**
- **Confirmation dialog exact wording**

An LLM choosing from ~4,000 SF Symbols, infinite color combinations, and many valid layout arrangements is unlikely to reproduce the same visual design.

**Probability of similar UI: ~25%**

---

## Combined probability estimates

### Scenario 1: "True drop-in" (binary-swap, users notice nothing)

Requires: bundle ID + UserDefaults keys + JSON schemas + UI + strings + colors + symbols all match.

**Probability: ~1-2%**

### Scenario 2: "Functional replacement" (same features, users must re-setup)

Requires: all features present, correct concurrency, similar UX flow. Accepts: different bundle ID (re-grant permissions), different persistence keys (lose history), different visual style.

**Probability: ~60-70%**

### Scenario 3: "Close enough with compatibility appendix"

If we add a **compatibility appendix** to the optimized prompts specifying:
- Exact bundle ID: `com.diskcleaner.app`
- All 5 UserDefaults keys verbatim
- All 4 Codable struct definitions verbatim
- Entitlements file content
- AccentColor RGB values
- Window default size
- Sidebar section order

**Probability of data-compatible replacement: ~50-65%**

The remaining gap comes from behavioral edge cases (thresholds, cap sizes, status timing) and UI styling that are hard to specify without essentially providing the source code.

---

## What would make it deterministic

To guarantee a true drop-in replacement, the prompts would need to include:

1. **All model definitions** as exact Swift code (~5 structs, ~60 lines)
2. **All UserDefaults keys** as a constant dictionary
3. **Bundle ID and entitlements** as exact files
4. **FileNode class definition** with all properties and key methods
5. **FileTypeClassifier** complete extension→category mapping
6. **SpaceWaster categories** with detection paths and risk levels
7. **DiskSpaceHistory compaction thresholds** as exact intervals
8. **All SF Symbol names** as a reference list
9. **Color definitions** as exact values

At that point, the "prompts" become a specification document of ~500-800 lines -- essentially a different form of the source code itself. The prompt chain shifts from "build me an app" to "implement this exact specification," which is a fundamentally different (and more reliable) mode of LLM code generation.

### The paradox of prompt-based reproducibility

The more reproducible you make a prompt chain, the closer it gets to being source code. The value of the prompt approach is *not* deterministic reproduction -- it's the ability to regenerate *similar functionality* on a different stack, with different trade-offs, or with architectural improvements that would be expensive to refactor in existing code.

The 8-prompt chain is best understood as a **functional specification** that produces an equivalent app, not a **build script** that produces an identical binary.
