---
agent: agent
tools: [codebase, runCommand, terminalLastCommand]
description: Show current state of all Copilot Forge work across the project
---

# status — Copilot Forge Status Dashboard

You are generating a status report of all Copilot Forge work in the current project.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Filter: [optional — REQ-xxx ID, "in-progress", "bugs", or nothing for full dashboard]

## Instructions

### Step 1: Scan All Copilot Forge artifacts

**Detect repository mode** — use the codebase tool to read `.forge/config.yml`. If it declares more than one `repos:` entry, this is **cross-repo mode**; otherwise **single-repo mode**.

1. Read all `requirement.md` files under `.forge/specs/REQ-*/` via the codebase tool.
2. Read all task files under `.forge/specs/REQ-*/tasks/`.
3. Read all bug reports under `.forge/bugs/`.
4. Read all `pipeline-state.json` files under `.forge/specs/REQ-*/` for live pipeline progress.
5. Extract frontmatter (`id`, `title`, `status`, `updated`) from each artifact.

**Cross-repo scan** (cross-repo mode only): for every sibling declared in `.forge/config.yml`, resolve its path and check `<sibling-path>/.forge/specs/REQ-*/pipeline-state.json` for REQs originating from that sibling that also touch this repo.

Run in terminal to get current branch and recent git state:
```bash
git branch --show-current
git log --oneline -5
```

### Step 2: Build Status Report

#### Requirements Summary Table
| ID | Title | Status | Tasks | Progress |
|----|-------|--------|-------|----------|

For each requirement: count total tasks, completed tasks, calculate progress %, show status.

#### Active Pipelines
If any `pipeline-state.json` files have `"completed": false`, show:
| REQ | Branch | Current Phase | Started | Last Phase Completed | Touched Repos |

Phase names: 0=Worktree, 1=Validate Spec, 2=Architect, 3=Validate Tasks, 4=Implement, 5=Verify, 6=Create PR, 7=PR Cleanup, 7.5=Canary, 8=Wrapup

#### Cross-Repo Activity (cross-repo mode only)
| REQ | Primary (origin) | Current Phase | This Repo's Role | Branch Here |
|-----|------------------|---------------|------------------|-------------|

"Branch Here" is detected by checking: `git branch --list feat/REQ-xxx-*`

#### In-Progress Work
List artifacts with status `in-review`, `approved`, or in-progress tasks.

#### Open Bugs
| ID | Title | Severity | Status | Updated |
|----|-------|----------|--------|---------|

#### Recently Completed
List artifacts completed in the last 7 days (by `updated` date).

### Step 3: Apply Filters (if provided)
- If a REQ ID is given: show detailed status for just that requirement and its tasks.
- If "in-progress": show only non-complete work.
- If "bugs": show only bug reports.
- If no filter: show the full dashboard.

### Step 4: Highlight Action Items
At the bottom, list recommended next actions:
- Specs that are `draft` and need validation
- Approved specs that need architecture/tasks
- Tasks that are ready to implement (dependencies met)
- Bugs that are `open` and unassigned
