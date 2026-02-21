# Reprompting: A Framework for Prompt-Driven Software Reproduction

## What is Reprompting?

Reprompting is the practice of **analyzing, extracting, optimizing, and replaying the prompts** that built an AI-assisted software project. It treats prompts as first-class development artifacts — version-controlled, documented, and reproducible — rather than ephemeral conversation inputs that disappear after a session.

The core insight: when you build software with an AI coding agent, the prompts you wrote *are* the source of the source code. If you preserve them, you can rebuild the software. If you analyze them, you can rebuild it *better*.

---

## Core Concepts

### 1. Prompt Chain

A **prompt chain** is the ordered sequence of prompts that produced a working application. Each prompt is a build step with inputs (existing code + context), requirements, and outputs (new/modified files).

In the DiskCleaner project, the original development used **81 prompts across 13 sessions** to produce a 4,804-line macOS app with 39 Swift files.

The prompt chain is the "source code of the source code" — it encodes not just what was built, but the order, dependencies, and decisions that shaped the architecture.

**See:** `promptdev/03-prompt-chain.md` — a runnable 10-prompt chain that reproduces the app from an empty Xcode project.

### 2. Prompt TLDRs

A **prompt TLDR** is a one-paragraph summary of what a prompt accomplished. TLDRs serve as a table of contents for the prompt chain: they let you understand the build sequence without reading the full prompts.

TLDRs answer: *What was built in this step? What files were created? What key decisions were made?*

**Example:**
> **P6: Treemap Visualization** — Implement squarified treemap algorithm and interactive Canvas rendering. Creates SquarifiedTreemap.swift, TreemapCanvasView.swift, TreemapContainerView.swift. Features: depth-based opacity, hover tooltip, zoom navigation, file type color legend.

**See:** `promptdev/02-prompt-tldrs.md`

### 3. Prompt Replay (Reprompting)

**Replaying** means feeding the prompt chain into a fresh AI coding agent to reproduce the application from scratch. This is the core act of "reprompting."

Three replay modes:

| Mode | Description | Fidelity | Effort |
|------|-------------|----------|--------|
| **Sequential replay** | Run each prompt from the chain one by one | High | Medium |
| **Optimized replay** | Run a compressed/improved chain | Medium | Low |
| **Golden prompt** | Run a single dense prompt | Lower | Minimal |

Sequential replay is most faithful because each prompt builds on the actual output of the previous one. The golden prompt is fastest but most likely to drift from the original.

### 4. Combining Prompts with Git History

The `prompts/` archive links every prompt to its **git commits**, creating a bidirectional mapping:

- **Forward:** Prompt → What code changed
- **Backward:** Commit → What prompt caused it

This mapping enables:
- **Archaeology:** Understanding *why* code looks the way it does by reading the prompt that produced it
- **Blame:** Tracing bugs to the prompt that introduced them
- **Optimization:** Identifying which prompts were productive vs. wasted effort

**Example from the archive:**

| Session | Prompts | Theme | Commits |
|---------|---------|-------|---------|
| 03 | 7 | Core build | `e6bbfbb` |
| 04 | 11 | Uninstaller, auto-scan | `a8371ac` `fc2c4bb` `086ee4a` |
| 12 | 27 | Swift 6 migration | `ae2474a` `c346a5f` |

Session 12 stands out: 27 prompts for a migration that could have been avoided by targeting Swift 6 from the start. This insight directly informs the optimized rebuild.

### 5. Prompt Chain Optimization

**Optimization** compresses the original prompt chain by:

1. **Eliminating retries** — Bug fixes caused by underspecified prompts get folded back into the original prompt
2. **Batching related work** — Features split across sessions merge into single prompts
3. **Encoding discovered knowledge** — Platform quirks, concurrency patterns, and edge cases specified upfront instead of discovered through debugging
4. **Removing waste** — Operational prompts (git push, check build), informational questions, and side quests are dropped

**DiskCleaner results:**

| Category | Original | Optimized |
|----------|----------|-----------|
| Total prompts | 81 | 8 |
| Bug fix prompts | 5 | 0 |
| Migration prompts | 22 | 0 |
| CI debug/retry | 7 | 0 |
| Operational | 8 | 1 |

**90% reduction** — from 81 prompts to 8.

The optimized chain isn't just shorter; it's *smarter*. It encodes knowledge that was discovered over 17 hours of development: correct concurrency patterns, platform quirks (`base64 -D` not `-d` on macOS), feature interaction bugs, and architectural decisions.

**See:** `prompts/OPTIMIZED-REBUILD.md`

### 6. Rebuild Fidelity

**Fidelity** measures how closely a replayed build matches the original. The `REBUILD-FIDELITY-ANALYSIS.md` document analyzes this across 9 dimensions:

| Dimension | Match Probability |
|-----------|-------------------|
| Bundle identifier | ~5% |
| UserDefaults keys | ~10% |
| JSON schemas | ~10% |
| Feature completeness | ~85% |
| Concurrency correctness | ~80% |
| UI layout & feel | ~25% |
| Exact string literals | ~5% |

**Key finding:** A "true drop-in replacement" (binary-swap, users notice nothing) has ~2% probability. A "functional replacement" (same features, different identity) has ~60-70%.

This reveals **the paradox of prompt-based reproducibility**: the more reproducible you make a prompt chain, the closer it gets to being source code. The value of reprompting is not deterministic reproduction — it's the ability to regenerate similar functionality on a different stack, with improvements, or as a learning artifact.

### 7. Golden Prompt

A **golden prompt** is a single, maximally-dense prompt that attempts to recreate an entire application in one shot. It's the ultimate compression of a prompt chain.

The DiskCleaner golden prompt (`promptdev/06-golden-first-prompt.md`) is ~200 lines specifying every model, service, view, and behavioral requirement.

Golden prompts trade reliability for convenience. They work best when:
- Paired with a conventions document as system context
- The target app has clear, well-understood architecture
- The developer can iterate on output (not truly one-shot)

If a golden prompt drifts, the fallback is the sequential prompt chain.

---

## The PromptDev Workflow

```
1. BUILD          →  Develop software with AI agent, naturally
2. ARCHIVE        →  Save all prompts + map to git commits
3. ANALYZE        →  Create TLDRs, dependency graphs, conventions
4. OPTIMIZE       →  Compress chain, encode lessons learned
5. ASSESS         →  Measure rebuild fidelity, identify gaps
6. REPLAY         →  Reproduce on fresh agent or different stack
7. ITERATE        →  Update the chain as the software evolves
```

### What gets produced

| Artifact | Purpose |
|----------|---------|
| `prompts/` archive | Chronological record of every prompt + git mapping |
| `promptdev/01-app-analysis.md` | Architecture analysis of what was built |
| `promptdev/02-prompt-tldrs.md` | One-line summaries of each build step |
| `promptdev/03-prompt-chain.md` | Runnable reproduction recipe |
| `promptdev/04-dependency-graph.md` | File dependencies and build order |
| `promptdev/05-conventions.md` | Coding patterns to enforce during replay |
| `promptdev/06-golden-first-prompt.md` | Single-prompt rebuild attempt |
| `OPTIMIZED-REBUILD.md` | Compressed chain with lessons encoded |
| `REBUILD-FIDELITY-ANALYSIS.md` | How closely replay matches original |

---

## Why Reprompting Matters

### For individual developers
- **Knowledge capture:** The prompt chain records *decisions*, not just *code*. Why was this architecture chosen? What alternatives were considered? What bugs were encountered?
- **Faster rebuilds:** When you need to recreate something (new platform, major refactor, teaching), the optimized chain is dramatically faster than starting from scratch.
- **Learning artifact:** Reading your own prompt chain reveals patterns — what kinds of prompts produce good results, where you waste effort, how your collaboration style with AI evolves.

### For teams
- **Onboarding:** New developers read the prompt chain to understand not just what the code does, but how and why it was built that way.
- **Review:** Prompt chains are reviewable artifacts. A prompt that says "add auth" is a red flag; one that specifies JWT vs sessions, token storage, refresh strategy is reviewable.
- **Reproducibility:** If a project needs to be rebuilt (tech debt, platform migration, fork), the prompt chain is the starting point.

### For the AI-native development era
- **Prompts as source:** As more software is written by AI agents, the prompts become the primary creative artifact. Treating them as disposable is like not using version control.
- **Prompt engineering meets software engineering:** Reprompting applies software engineering principles (versioning, testing, optimization, documentation) to the prompt development process.
- **Stack independence:** A well-written prompt chain can target different languages, frameworks, or platforms — the same functional spec, different implementation.

---

## Lessons from DiskCleaner

The DiskCleaner project (built in 17 hours, 81 prompts, single developer + Claude) demonstrated several reprompting principles:

1. **The mega-prompt anti-pattern:** Session 1 was a 70-line mega-prompt specifying everything. It was abandoned immediately. Session 2 was one sentence: *"we're building macos native app... create a plan. ask questions if unsure."* The collaborative approach worked vastly better.

2. **Planning prompts compound:** The "plan → implement" rhythm (plan in one session, implement in the next) was the most productive pattern. Planning prompts are high-leverage — they prevent bugs, establish architecture, and create shared understanding.

3. **Migration is avoidable waste:** 27 of 81 prompts (33%) were spent on Swift 5→6 migration. Targeting Swift 6 from the start eliminates this entirely. The optimized chain encodes this lesson.

4. **Bug fixes encode missing requirements:** Every bug fix prompt reveals a requirement that the original prompt failed to specify. Folding these back into the prompt chain makes future replays bug-free.

5. **Operational prompts are noise:** "git push", "check build", "download DMG" — these are real development activities but add nothing to the prompt chain. The optimized rebuild drops them entirely.

6. **Fidelity has a ceiling:** Even with detailed prompts, reproducing an identical app is nearly impossible (~2%). But reproducing equivalent functionality is likely (~65%). The gap is filled by identifiers, schemas, exact strings, and visual styling — details that are hard to specify in prompts without becoming source code.
