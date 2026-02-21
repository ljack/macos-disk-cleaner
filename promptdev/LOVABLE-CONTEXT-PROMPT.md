# Context Prompt for Lovable AI

Copy everything below this line and paste it into Lovable to update https://repromptable.lovable.app/

---

Redesign and populate the site as a concept explainer and landing page for "Reprompting" — a framework for prompt-driven software reproduction. The site should explain the concept clearly, show a real-world case study, and feel like a polished developer-tools landing page (think Linear, Raycast, or Warp aesthetics — clean, dark-mode-first, monospace accents, sharp).

## Site Structure

### Hero Section
- Title: **"Reprompting"**
- Subtitle: "Analyze, optimize, and replay the prompts that built your software."
- One-liner: "Treat prompts as first-class development artifacts. Version them. Optimize them. Reproduce your software from them."
- CTA button: "See the Case Study" (scrolls to case study section)
- Secondary link: "Read the full framework" linking to the GitHub repo's promptdev/REPROMPTING.md

### Section 1: "What is Reprompting?"
Three-column card layout:

**Card 1: Archive**
- Icon: file/document
- "Save every prompt alongside its git commits. Map conversations to code changes. Build a development archaeology you can trace backward from any line of code."

**Card 2: Optimize**
- Icon: compress/filter
- "Analyze your prompt chain. Fold bug fixes back into original prompts. Encode discovered knowledge. Eliminate migration overhead and retry loops."
- Stat callout: "81 prompts → 8 (90% reduction)"

**Card 3: Replay**
- Icon: play/refresh
- "Feed the optimized chain into a fresh AI agent. Reproduce your app from scratch — same features, better architecture, different stack if you want."

### Section 2: "The Prompt Chain"
Visual pipeline/flow diagram showing the lifecycle:

```
BUILD → ARCHIVE → ANALYZE → OPTIMIZE → ASSESS → REPLAY → ITERATE
```

Each step as a node with a one-line description:
- BUILD: "Develop software with AI, naturally"
- ARCHIVE: "Save prompts + map to git commits"
- ANALYZE: "Create TLDRs, dependency graphs, conventions"
- OPTIMIZE: "Compress chain, encode lessons learned"
- ASSESS: "Measure rebuild fidelity, identify gaps"
- REPLAY: "Reproduce on fresh agent or different stack"
- ITERATE: "Update chain as software evolves"

### Section 3: "Case Study: DiskCleaner"
Real-world case study with stats and narrative. Use a two-column layout with stats on one side and narrative on the other.

**Stats sidebar (use metric cards):**
- Development time: 17 hours
- Original prompts: 81
- Optimized prompts: 8
- Reduction: 90%
- Lines of Swift: 4,804
- Source files: 39
- Git commits: 25
- Developer count: 1 + AI agent

**Narrative column:**

"DiskCleaner is a native macOS disk space analyzer sold on the App Store. It was built from zero to signed release in a single 17-hour session by one developer collaborating with Claude Code (Opus).

The first attempt was a 70-line mega-prompt specifying every detail upfront. It was abandoned within minutes. The second attempt was one sentence: 'We're building a macOS native app that lets users figure out where disk space is used and clean things up. Create a plan. Ask questions if unsure.'

That collaborative approach produced 81 prompts across 13 sessions — but analysis revealed that only 22 were actual feature implementation. The rest were bug fixes (5), Swift 5→6 migration (22), planning sessions (8), operational noise (8), CI debugging loops (7), and informational questions (6).

The optimized rebuild compresses everything into 8 prompts that encode all discovered knowledge: correct concurrency patterns from the start, platform quirks specified upfront, feature interactions as requirements instead of bug reports."

### Section 4: "Where Prompts Went" (analysis visualization)
Horizontal stacked bar chart or breakdown showing the 81 prompts categorized:

| Category | Count | Note |
|----------|-------|------|
| Feature implementation | 22 | The actual productive work |
| Swift 6 migration | 22 | Avoidable — target Swift 6 from start |
| Planning sessions | 8 | High leverage — merged into impl prompts |
| Operational (git, CI) | 8 | Noise — dropped in optimized chain |
| CI debugging loops | 7 | Encoded as upfront requirements |
| Informational | 6 | Learning, not building |
| Bug fixes | 5 | Folded back into original prompts |
| Side quests | 1 | PromptOps analysis itself |
| Empty/crashed | 2 | Session artifacts |

Callout: "33% of all prompts were spent migrating Swift 5 → 6. Targeting Swift 6 from the start eliminates this entire category."

### Section 5: "Rebuild Fidelity"
The fidelity paradox — what happens when you replay prompts.

Show a fidelity spectrum/gauge:

- **True drop-in replacement** (identical binary): ~2% probability
  - "Requires matching bundle ID, UserDefaults keys, JSON schemas, all UI strings, colors, and SF Symbol choices"
- **Data-compatible replacement** (reads existing user data): ~50-65%
  - "With a compatibility appendix specifying exact identifiers and schemas"
- **Functional replacement** (same features, fresh identity): ~60-70%
  - "Users must re-grant permissions and lose history, but all features work"

Quote block: "The paradox of prompt-based reproducibility: the more reproducible you make a prompt chain, the closer it gets to being source code. The value isn't deterministic reproduction — it's regenerating similar functionality on a different stack, with improvements that would be expensive to refactor."

### Section 6: "Reprompting Artifacts"
Grid of artifact cards showing what gets produced:

| Artifact | Purpose |
|----------|---------|
| Prompt archive | Every prompt + git commit mapping |
| App analysis | Architecture breakdown of what was built |
| Prompt TLDRs | One-line summaries of each build step |
| Prompt chain | Runnable reproduction recipe |
| Dependency graph | File dependencies and build order |
| Conventions doc | Coding patterns to enforce during replay |
| Golden prompt | Single-prompt rebuild attempt |
| Optimized rebuild | Compressed chain with lessons encoded |
| Fidelity analysis | How closely replay matches original |

### Section 7: "Key Insights"
Three insight cards with icons:

**1. "Planning prompts compound"**
"The plan → implement rhythm was the most productive pattern. Planning prompts prevent bugs, establish architecture, and create shared understanding before code is written."

**2. "Bug fixes are missing requirements"**
"Every bug fix prompt reveals a requirement the original prompt failed to specify. Folding fixes back makes future replays bug-free from the start."

**3. "The mega-prompt anti-pattern"**
"A 70-line mega-prompt was abandoned immediately. One collaborative sentence produced a better architecture. Conversation beats specification."

### Footer
- "Built with prompts. Analyzed with prompts. Reproducible from prompts."
- Link to GitHub repo (use placeholder URL)
- Link to the full REPROMPTING.md document
- "Made by Jarkko" credit

## Design Requirements
- Dark mode first, with light mode support
- Monospace font for stats, code snippets, and the pipeline diagram
- Sans-serif (Inter or similar) for body text
- Accent color: blue-purple gradient (similar to the pipeline concept of transformation)
- Smooth scroll animations between sections
- Responsive — works on mobile but optimized for desktop reading
- No stock photos or illustrations — use typography, spacing, and data visualization
- The stacked bar chart and fidelity gauge should be actual rendered components, not images
- Keep it minimal — let the data and concepts speak
