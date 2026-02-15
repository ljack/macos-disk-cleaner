# PromptDev in This Repository

## Purpose

This document explains how DiskCleaner acts as a concrete PromptDev implementation that can be paired with the Repromptable business site (`https://repromptable.lovable.app/`).

The business site communicates the idea. This repository shows one end-to-end realization of that idea in a real app.

## Concept Summary (from the business-site framing)

The site positions PromptDev as prompt-driven software delivery where teams can:

- Describe intent in natural language.
- Capture and organize AI interactions.
- Analyze what works.
- Summarize outcomes for stakeholders.
- Replay and verify implementation steps.

This repo supports that framing by preserving architecture context, prompt-chain artifacts, and reproducible implementation guidance.

## Why Pair the App with the Business Site

The business site explains the market problem (inconsistent AI output, low visibility, weak reproducibility).

This codebase provides proof of execution:

- A non-trivial macOS app is implemented.
- The implementation is decomposed into prompt-sized units.
- The process is documented so others can inspect and reproduce it.

Together, they show both the narrative and the operational model.

## `promptdev/` Folder Walkthrough

### `promptdev/00-index.md`
Entry point and reading order for all PromptDev materials.

### `promptdev/01-app-analysis.md`
Deep architectural analysis of DiskCleaner: modules, feature inventory, and design decisions.

### `promptdev/02-prompt-tldrs.md`
High-level summaries of each build prompt in the chain.

### `promptdev/03-prompt-chain.md`
Runnable prompt sequence for reproducing the app from scratch in an LLM coding agent.

### `promptdev/04-dependency-graph.md`
File dependency layers, build ordering, and prompt-to-file mapping.

### `promptdev/05-conventions.md`
Engineering conventions and constraints for consistent PromptDev output.

## Mapping Site Claims to Repo Artifacts

### Capture
- Prompt chain and structure captured in `promptdev/03-prompt-chain.md`.

### Analyze
- Architecture and design analysis in `promptdev/01-app-analysis.md`.
- Dependency analysis in `promptdev/04-dependency-graph.md`.

### Summarize
- Prompt-level summaries in `promptdev/02-prompt-tldrs.md`.
- Index and orientation in `promptdev/00-index.md`.

### Replay & Verify
- Stepwise reproducible prompt chain in `promptdev/03-prompt-chain.md`.
- Conventions in `promptdev/05-conventions.md` to keep reruns consistent.

## How Interested Teams Can Use This

1. Read `promptdev/00-index.md` and `promptdev/01-app-analysis.md`.
2. Review constraints in `promptdev/05-conventions.md`.
3. Execute `promptdev/03-prompt-chain.md` sequentially with an LLM coding agent.
4. Use `promptdev/04-dependency-graph.md` to reason about extension and refactor order.
5. Compare outcomes against this repo to evaluate reproducibility.

## What This Demonstrates

- Prompt-native development can produce a real product, not just prototypes.
- Prompt assets can be versioned alongside source code.
- Teams can make AI development more inspectable and repeatable.

## Scope Note

This is one implementation pattern for PromptDev, not the only one.

Other teams can reuse the same structure with different stacks, domains, or governance requirements while keeping the same core loop: capture, analyze, summarize, replay, verify.
