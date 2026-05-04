---
agent: agent
tools: [codebase, runCommand, terminalLastCommand]
description: Detect drift between this project's .forge/templates/ copies and the canonical templates in the toolkit
---

# template-drift — Template Drift Detector

You are checking whether the project's local `.forge/templates/` copies still match the canonical templates in the copilot-forge. Templates are copied per-repo (not symlinked), so they drift over time. Some drift is **intentional** (project-specific customization); some is **accidental** (toolkit updated and the project never pulled the change).

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
>

## Input

Scope: [optional — single template name to check (e.g., `requirement-template`), otherwise check all templates]

## Prerequisites

1. `.forge/templates/` must exist in the current project. If not, stop: "This project has no local templates. No drift to check."
2. Identify the canonical templates directory. It is `templates/` at the toolkit root (the parent of `.github/`). Use the codebase tool to locate it. If not found, stop: "Cannot find the canonical toolkit templates directory."

## Instructions

### Step 1: Enumerate Templates to Compare
1. If the user passed a scope argument, only check `.forge/templates/<scope>.md` vs the canonical `<scope>.md`.
2. Otherwise, list every `*.md` file in `.forge/templates/` AND every `*.md` in the canonical `templates/`. Compare the union — this catches templates added upstream but not yet in the project, and templates in the project not in the toolkit.

### Step 2: Diff Each Template
For each template, use the codebase tool to read both versions and compare them. Capture:
- **Missing upstream**: template exists locally but not in toolkit (legacy or custom)
- **Missing locally**: template exists in toolkit but not in project (upstream added, not yet copied)
- **Identical**: no differences
- **Drifted**: differences — count added/removed lines

Also compute a rough drift size: total lines added + total lines removed.

Run in terminal for a precise diff (substitute actual paths):
```bash
diff -u <toolkit-templates>/<name>.md .forge/templates/<name>.md
```

### Step 3: Classify Drift as Intentional vs Accidental

For each drifted template, read both full versions and make a judgment call:

**Intentional customization signals** (do NOT reconcile without explicit user consent):
- Added sections specific to this project (e.g., `## System Model`, `## Business Rules` added to `requirement-template.md`)
- Added frontmatter fields referencing project-specific concepts
- Rewritten wording reflecting a deliberate editorial choice

**Accidental staleness signals** (SHOULD reconcile):
- Toolkit added a new section or field and the project's copy is structurally older
- Cosmetic-only differences (whitespace, placeholder text)
- Toolkit renamed/removed a section that the project still has dangling
- Toolkit tightened a rule and the project's copy shows the old rule

When in doubt, classify as "needs human review."

### Step 4: Produce the Drift Report

```
## Template Drift Report — [date]

Project: <repo name>
Canonical templates: <path to toolkit templates/>

| Template | Status | Drift | Classification |
|---|---|---|---|
| requirement-template.md | Drifted | +42 / -8 | Intentional (System Model, Entities) |
| task-template.md | Drifted | +3 / -1 | Accidental (cosmetic) |
| bug-template.md | Identical | — | — |
| assumption-template.md | Missing locally | — | Upstream added — needs copy |

Overall: 3 drifted, 1 missing locally, 1 identical.
Intentional: 1. Accidental: 2. Missing: 1.
```

Then, for each non-identical template, write a short per-file section describing:
- What the project has that the toolkit doesn't (intentional additions)
- What the toolkit has that the project is missing (accidental staleness)
- Proposed action

### Step 5: Offer Reconciliation Actions

For each **accidental** drift and each **missing locally** template, offer a specific action:

```
## Proposed Actions

1. **task-template.md**: Copy from toolkit to project (accidental cosmetic drift).
   Action: copy <toolkit-templates>/task-template.md → .forge/templates/task-template.md

2. **assumption-template.md**: Copy from toolkit to project (upstream added, not yet in project).
   Action: copy <toolkit-templates>/assumption-template.md → .forge/templates/assumption-template.md

Reply with action numbers to apply (e.g. "1 2" or "all"), or "skip" to take no action.
```

**Do not apply any changes without explicit user approval.** Writing to `.forge/templates/` affects how future `#spec`, `#architect`, and `#bugfix` runs behave.

For **intentional** drift, do not propose reconciliation — just note it in the report.

If the user approves, apply only the numbered actions they listed and re-diff those files to confirm drift is now zero.

### Step 6: Recommend Follow-Up
- If all drift is intentional or reconciled: "All templates are in sync or intentionally customized."
- If drift remains after user-approved actions: list what's still drifted.
- If intentional customizations were found: remind the user to document them in a project NOTES file so future toolkit updates don't accidentally overwrite them.

## What This Skill Does NOT Do
- Does not modify toolkit templates — changes to the canonical version go through the copilot-forge repo.
- Does not rename or delete project template files — only copies or reports.
- Does not check drift of prompts or agents — those would need to be re-copied manually from the toolkit's `.github/prompts/` directory.
