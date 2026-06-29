# Copilot Forge — Comprehensive Sanity Check Report

> **Date**: 2026-06-29  
> **Scope**: All prompts, agents, scripts, templates, context files, knowledge base, and dependency graph

---

## Executive Summary

| Category | Total | ✅ Pass | ❌ Fail | ⚠️ Warn |
|---|---|---|---|---|
| Prompt Frontmatter | 40 | 33 | 5 | 2 |
| Dependency Graph | 1 | 0 | 1 | 0 |
| Template Files | 15 | 15 | 0 | 0 |
| Scripts | 7 | 7 | 0 | 0 |
| Context Files | 8 | 8 | 0 | 0 |
| Knowledge Base | 10 | 10 | 0 | 0 |
| Encoding | 40 | 25 | 15 | 0 |

**Overall Verdict**: ❌ **5 blockers, 15 encoding issues, 2 warnings** — see details below.

---

## 🔴 Blockers (Must Fix)

### 1. `forge-proceed.prompt.md` — Missing YAML Frontmatter

[forge-proceed.prompt.md](file:///d:/2026/ai-corner/copilot-forge/.github/prompts/forge-proceed.prompt.md)

> [!CAUTION]
> The most critical prompt in the entire framework has **no YAML frontmatter**. Line 1 is `---` immediately followed by `## Step 0:` on line 3. There is no `agent:`, `tools:`, or `description:` field. GitHub Copilot Chat will not recognize this as an agent-mode prompt.

**Expected (example)**:
```yaml
---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: End-to-end pipeline for a single REQ — spec → architect → TDD → implement → verify → PR → merge
---
```

---

### 2. `forge-proceed.prompt.md` — Duplicate Phase Content (Lines 240–438)

[forge-proceed.prompt.md:L240-L438](file:///d:/2026/ai-corner/copilot-forge/.github/prompts/forge-proceed.prompt.md#L240-L438)

> [!CAUTION]
> The file contains **two copies** of Phases 1–8 and Error Handling. The first copy starts at line 39, the second at line 240. The two versions are **not identical** — they diverge at Phase 5:
> - **First copy** (L111): `## Phase 5: Verify (Computational & Inferential)` — includes both Part 1 (computational gates) and Part 2 (inferential reviewers). This is the **more complete version** with spec-adherence step.
> - **Second copy** (L310): `## Phase 5: Verify (Reflect + Review)` — inferential only, no computational gates, no spec-adherence step.
>
> This duplication wastes ~200 lines of context tokens and could cause the agent to follow the wrong Phase 5 variant.

**Fix**: Keep the first (L1–L238), delete the duplicate (L240–L438), and retain the `## Internal Reference` block at the end.

---

### 3. `forge-admin.prompt.md` — YAML Frontmatter Is a REQ Template, Not a Prompt Header

[forge-admin.prompt.md:L1-L10](file:///d:/2026/ai-corner/copilot-forge/.github/prompts/forge-admin.prompt.md#L1-L10)

> [!CAUTION]
> Lines 1–10 contain a **requirement-spec template** (`id: REQ-xxx`, `title: "<short title>"`, `status: complete`) instead of the prompt's YAML frontmatter. The actual frontmatter (`agent: agent`, `tools:`, `description:`) is buried at **lines 110–114** — after the first `---` block closes. Copilot will parse the REQ template as the frontmatter, breaking the prompt.

**Fix**: Delete lines 1–110 (the output template block that precedes the real prompt), or move the `agent:` / `tools:` / `description:` block to the top.

---

### 4. `forge-token-estimate.prompt.md` — Same Issue as `forge-admin`

[forge-token-estimate.prompt.md:L1-L3](file:///d:/2026/ai-corner/copilot-forge/.github/prompts/forge-token-estimate.prompt.md#L1-L3)

> [!CAUTION]
> Lines 1–2 are `---` then a blank line — no YAML fields. The real frontmatter (`agent: agent`, `tools: [codebase, runCommand]`, `description:`) is at **lines 135–139**. Everything before it (the output format template) will be parsed as frontmatter, breaking the prompt.

**Fix**: Move the `agent:` / `tools:` / `description:` block to lines 2–4 (inside the opening `---` fence).

---

### 5. 15 Agent Prompts — Missing Opening `---` Delimiter

> [!WARNING]
> All 15 agent prompts (in `agents/` and `agents/inferential/`) start with `agent: agent` on **line 1** without a preceding `---` delimiter. The YAML frontmatter spec requires `---` on the very first line.

**Affected files** (all under [.github/prompts/agents/](file:///d:/2026/ai-corner/copilot-forge/.github/prompts/agents)):

| File | Line 1 (actual) | Expected Line 1 |
|---|---|---|
| `forge-api-cost-scanner.prompt.md` | `agent: agent` | `---` |
| `forge-architecture-mapper.prompt.md` | `agent: agent` | `---` |
| `forge-db-perf-scanner.prompt.md` | `agent: agent` | `---` |
| `forge-feature-tracer.prompt.md` | `agent: agent` | `---` |
| `forge-integration-explorer.prompt.md` | `agent: agent` | `---` |
| `forge-latency-scanner.prompt.md` | `agent: agent` | `---` |
| `forge-reflector.prompt.md` | `agent: agent` | `---` |
| `forge-task-implementer.prompt.md` | `agent: agent` | `---` |
| **inferential/** `forge-architecture-reviewer.prompt.md` | `agent: agent` | `---` |
| **inferential/** `forge-code-quality-auditor.prompt.md` | `agent: agent` | `---` |
| **inferential/** `forge-convention-auditor.prompt.md` | `agent: agent` | `---` |
| **inferential/** `forge-correctness-reviewer.prompt.md` | `agent: agent` | `---` |
| **inferential/** `forge-quality-reviewer.prompt.md` | `agent: agent` | `---` |
| **inferential/** `forge-security-auditor.prompt.md` | `agent: agent` | `---` |
| **inferential/** `forge-test-auditor.prompt.md` | `agent: agent` | `---` |

> [!NOTE]
> GitHub Copilot *may* still parse these correctly (some parsers are lenient about the opening `---`), but per the YAML frontmatter spec these are technically malformed. This is a **warning** rather than a guaranteed break — but fixing it is trivial and removes the risk.

---

## 🟡 Encoding Issue (15 files)

All 15 agent prompt files contain a **mojibake character** (`�`) in the Context Loading Rule section:

```
1. ALWAYS read .forge/context/rules/ files � these are your constraints.
```

The `�` is a Unicode replacement character (U+FFFD), likely a corrupted em-dash (`—`) or a right arrow (`→`). This won't break parsing but looks unprofessional and could confuse the LLM.

**Affected**: Every file in `agents/` and `agents/inferential/` (15 total).

**Fix**: Replace `�` with `—` (em-dash) in all 15 files.

---

## ⚠️ Warnings

### 1. Dependency Graph — Stale Nodes

[forge-dependency-graph.md](file:///d:/2026/ai-corner/copilot-forge/.forge/knowledge/forge-dependency-graph.md)

The Mermaid graph's `style` block references nodes that **do not exist in the graph edges**:

| Stale Node ID | Likely Source |
|---|---|
| `agents/computational\test_gate` | `agents/computational/` dir exists but no edge references it |
| `agents/computational\build_gate` | Same |
| `agents/computational\typecheck_gate` | Same |
| `agents/computational\lint_gate` | Same |
| `agents/computational\secret_scan` | Same |
| `agents/computational\vuln_scan` | Same |
| `agents/inferential\*` (8 nodes) | `agents/inferential/` dir exists but no edge references them |
| `process\*` (7 nodes) | `templates/process/*.rules.md` exists but has no edges |
| `forge_test_ps1` | `scripts/forge-test.ps1` exists but no prompt declares a dependency on it |
| `forge_context_ps1` | `scripts/forge-context.ps1` exists but no prompt declares a dependency on it |

The graph only has **edges** for 8 agents (`agents/reflector`, `agents/task_implementer`, `agents/architecture_mapper`, etc.) but styles 22+ more. This means:
- The computational agent prompts exist on disk but are **not wired into the dependency graph edges**.
- The process rules exist on disk but are **not wired into the dependency graph edges**.
- `forge-proceed` references computational agents in its body but the graph doesn't have edges for `proceed → agents/computational/*`.

**Cause**: The graph generator script (`generate-graph.ps1`) likely only parses `Internal Reference` blocks. The computational agents are referenced inline in `forge-proceed` body text, not in `Internal Reference`.

### 2. `forge-proceed.prompt.md` — Phase 5 Version Conflict

As noted in Blocker #2, there are two versions of Phase 5:
- **V1** (L111): "Verify (Computational & Inferential)" — 7 inferential steps (A–G) including `spec-adherence`
- **V2** (L310): "Verify (Reflect + Review)" — 6 inferential steps (A–F), no `spec-adherence`, no computational gates

The `Internal Reference` block only lists **8 outgoing skill deps** and **2 outgoing agent deps** — matching V1. V2 appears to be an older draft that was not removed.

---

## ✅ What's Working Well

### Prompts — Structure & Content
- **24/26 top-level prompts** have correct frontmatter (`agent:`, `tools:`, `description:`) and valid structure
- All prompts reference `.github/copilot-instructions.md` for ethos
- `Internal Reference` blocks are present on all prompts — enables dependency tracking
- The prompt naming convention (`forge-<verb>.prompt.md`) is 100% consistent

### Templates (15 files) — All Present and Well-Formed
All template files in [templates/](file:///d:/2026/ai-corner/copilot-forge/templates) exist and contain valid frontmatter/structure:
`adr-template.md`, `assumption-template.md`, `bug-template.md`, `config-template.yml`, `deployment-template.md`, `env-local-template.env`, `inbox-template.md`, `lesson-template.md`, `manual-qa-template.md`, `requirement-template.md`, `support-template.md`, `task-template.md`, `taxonomy-template.md`, `variables-template.md`, `vibe-template.md`

### Process Rules (9 files) — All Present
All rules in [templates/process/](file:///d:/2026/ai-corner/copilot-forge/templates/process) exist: `context-budget`, `escalation`, `grounding`, `iron-laws`, `pushback`, `scoping`, `self-validation`, `subagent-trust`, `surgical-edits`

### Scripts (7 files) — All Present and Functional
- [forge-context.ps1](file:///d:/2026/ai-corner/copilot-forge/scripts/forge-context.ps1) ✅
- [forge-gate.ps1](file:///d:/2026/ai-corner/copilot-forge/scripts/forge-gate.ps1) ✅
- [forge-test.ps1](file:///d:/2026/ai-corner/copilot-forge/scripts/forge-test.ps1) ✅
- [generate-graph.ps1](file:///d:/2026/ai-corner/copilot-forge/scripts/generate-graph.ps1) ✅
- [install.ps1](file:///d:/2026/ai-corner/copilot-forge/scripts/install.ps1) ✅
- [token-estimate.ps1](file:///d:/2026/ai-corner/copilot-forge/scripts/token-estimate.ps1) ✅
- [update.ps1](file:///d:/2026/ai-corner/copilot-forge/scripts/update.ps1) ✅

### Context Files (8 files) — All Present
- [project-overview.md](file:///d:/2026/ai-corner/copilot-forge/.forge/context/project-overview.md) ✅
- Corpus: `architecture.md`, `conventions.md`, `copilot_forge_flow_demo.md`, `variables.md` ✅
- Rules: `architecture.rules.md`, `conventions.rules.md`, `deployment.rules.md`, `security.rules.md` ✅

### Knowledge Base — Populated
- 3 lessons, 5 support articles, 1 dependency graph, 6 specs ✅
- [copilot-instructions.md](file:///d:/2026/ai-corner/copilot-forge/.github/copilot-instructions.md) — 7 Iron Laws + 6 principles ✅

### Cross-Reference Integrity
- All skill references in `Internal Reference` blocks (`#forge-*`) map to existing prompt files ✅
- All agent references (`#agents/*`) map to existing agent prompt files ✅
- All template references in prompt bodies map to existing template files ✅
- All script references (`forge-gate.ps1`, `forge-test.ps1`, `forge-context.ps1`) map to existing scripts ✅

---

## Existing Sanity Check Prompt

> [!TIP]
> The repo already has **`#forge-admin`** which includes audit capabilities. However, `forge-admin` is currently broken (Blocker #3 above — its frontmatter is a REQ template). Once fixed, you can use it for governance operations.
>
> For **template drift** checking, use **`#forge-template-drift`** — it compares your project's `.forge/templates/` copies against the canonical templates in the toolkit.
>
> For **convention drift** checking, use **`#forge-check-drift`** — a lightweight read-only compliance scan.

---

## Recommended Fix Priority

| Priority | Fix | Files | Impact |
|---|---|---|---|
| 🔴 P0 | Add frontmatter to `forge-proceed` | 1 | Pipeline completely broken |
| 🔴 P0 | Remove duplicate Phases 1–8 from `forge-proceed` | 1 | Agent confusion, token waste |
| 🔴 P0 | Fix `forge-admin` frontmatter position | 1 | Admin prompt broken |
| 🔴 P0 | Fix `forge-token-estimate` frontmatter position | 1 | Token estimate prompt broken |
| 🟡 P1 | Add opening `---` to all 15 agent prompts | 15 | Spec compliance |
| 🟡 P1 | Fix `�` encoding in 15 agent prompts | 15 | Cosmetic + LLM clarity |
| 🟢 P2 | Regenerate dependency graph with full edges | 1 | Graph accuracy |

---

## Fixes Applied

1. Fixed forge-proceed.prompt.md missing frontmatter and duplicate content.
2. Fixed forge-admin.prompt.md frontmatter position.
3. Fixed forge-token-estimate.prompt.md frontmatter position.
4. Added missing '---' to 22 agent prompts.
5. Fixed mojibake characters in all agent prompts.

