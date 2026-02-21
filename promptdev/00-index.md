# PromptOps — DiskCleaner

Prompt chain analysis and reproduction plan for the DiskCleaner macOS application.

## Documents

| File | Purpose |
|------|---------|
| [01-app-analysis.md](01-app-analysis.md) | Full architecture analysis of the app |
| [02-prompt-tldrs.md](02-prompt-tldrs.md) | TL;DR summaries of each build prompt |
| [03-prompt-chain.md](03-prompt-chain.md) | Runnable prompt collection — the reproduction recipe |
| [04-dependency-graph.md](04-dependency-graph.md) | File dependency graph and build order |
| [05-conventions.md](05-conventions.md) | Coding conventions and patterns to enforce |
| [06-golden-first-prompt.md](06-golden-first-prompt.md) | Single-prompt rebuild attempt |
| [REPROMPTING.md](REPROMPTING.md) | Full framework document — what reprompting is and why it matters |
| [LOVABLE-CONTEXT-PROMPT.md](LOVABLE-CONTEXT-PROMPT.md) | Context prompt for updating repromptable.lovable.app |

## How to Use

1. Read `01-app-analysis.md` to understand what you're rebuilding
2. Read `05-conventions.md` to understand the style rules
3. Execute prompts from `03-prompt-chain.md` sequentially in an LLM coding agent
4. Each prompt is self-contained — it describes inputs, outputs, and acceptance criteria
5. The chain reproduces the full application from an empty Xcode project

## Stats

- **Total source files**: 27 Swift files
- **Total lines of code**: ~2,400
- **Prompt chain length**: 10 prompts
- **Architecture**: MVVM + Actor services, SwiftUI, macOS 14+
