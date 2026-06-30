---
agent: agent
tools: [codebase, runCommand, terminalLastCommand]
description: Lightweight read-only convention compliance check — flags drift without auto-fixing
---

# check-drift — Fast Convention Compliance Check

You are performing a fast, lightweight convention compliance spot-check on recently changed files. This is a **read-only** check — you report findings but **never auto-fix** anything.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Scope: [optional — specific file paths, branch name, or nothing for current uncommitted + staged changes]

## Prerequisites

Use the codebase tool to verify `.forge/context/rules/conventions.rules.md` exists. If it doesn't, stop and tell the user: "The `.forge/` structure hasn't been initialized. Run `#forge-init` first."

## Instructions

### Step 1: Load All Rules
Read every `.rules.md` file in `.forge/context/rules/` via the codebase tool:
- `architecture.rules.md`
- `conventions.rules.md`
- `security.rules.md`
- `deployment.rules.md`
- Any additional `.rules.md` files present.

### Step 2: Identify Changed Files
Run in the terminal to get the list of changed files:
```powershell
git diff --name-only HEAD
git diff --name-only --cached
git diff --name-only main...HEAD 2>$null
```
Merge the results into a deduplicated list. If the user provided specific file paths, use those instead.

Exclude non-source files (images, lock files, `.gitignore`, generated files).

### Step 3: Check Each File Against Rules
For each changed file, read the full file content via the codebase tool. Compare it against every applicable rule:

- **Architecture rules**: layering violations, dependency direction, business logic placement
- **Convention rules**: naming, logging, config, error handling, import style, API format
- **Security rules**: hardcoded secrets, missing auth checks, PII exposure
- **Deployment rules**: deployment pattern compliance

### Step 4: Classify Findings

Classify each finding into exactly one severity tier:

| Tier | Label | Meaning | Action |
|------|-------|---------|--------|
| 🔴 | **IRON LAW** | Hard violation that will break the pipeline or compromise security | Must fix before continuing |
| 🟡 | **GOLDEN PATH** | Deviation from recommended patterns — code works but diverges from conventions | Warning — note for review |
| 🔵 | **RULE** | Minor rule infraction — style, naming, or formatting | Info — fix before commit |

### Step 5: Report

Present findings in a compact drift report:

```markdown
## 🔍 Drift Report

**Files scanned**: N
**Findings**: X total (R 🔴 / Y 🟡 / Z 🔵)

### 🔴 IRON LAW Violations
| File | Line | Rule | Finding |
|------|------|------|---------|
| ... | ... | ... | ... |

### 🟡 GOLDEN PATH Deviations
| File | Line | Rule | Finding |
|------|------|------|---------|
| ... | ... | ... | ... |

### 🔵 RULE Infractions
| File | Line | Rule | Finding |
|------|------|------|---------|
| ... | ... | ... | ... |

**Verdict**: CLEAN / DRIFT DETECTED
```

If no findings: report `**Verdict**: CLEAN ✅ — No convention drift detected.`

> **IMPORTANT**: This is a read-only check. Do NOT modify any files. Do NOT offer to fix anything. Just report.

## Internal Reference
- **Incoming Skill Dependencies**: `#forge-proceed`
- **Incoming Agent Dependencies**: *None*
- **Outgoing Skill Dependencies**: *None*
- **Outgoing Agent Dependencies**: *None*
- **Resource Dependencies**: *None*
