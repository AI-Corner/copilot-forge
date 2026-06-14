---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Close out a completed feature — commit, merge, deploy, capture knowledge, emit ship summary
---

# wrapup — Feature Completion Wrap-Up

You are closing out a completed feature after it has been merged. This skill ensures Copilot Forge artifacts are finalized, knowledge is captured, and the team has a clear summary of what shipped.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
> **Focus**: Act as the release manager. Only use `.forge/context/*.md`, the REQ’s `requirement.md`, its tasks, and the current code state; ignore any earlier chat history or brainstorming.

## Input

Target: [REQ-xxx ID — provided by the user]

## Instructions

### ⛔ Pre-flight Gate (Run This First — Do Not Skip)

Run this command via terminal **before doing anything else**:

```powershell
$reqFile = Get-ChildItem -Path ".forge/specs" -Recurse -Filter "requirement.md" | Select-Object -First 1
if (-not $reqFile) { Write-Error "GATE FAILED: No requirement.md found. Nothing to wrap up."; exit 1 }
$status = ((Get-Content $reqFile.FullName | Select-String '^status:') -replace '^status:\s*','').Trim()
if ($status -eq 'complete') { Write-Warning "Warning: Requirement is already marked complete. Proceeding anyway (idempotent wrapup)." }
$taskDir = Join-Path (Split-Path $reqFile.FullName) "tasks"
$tasks = Get-ChildItem -Path $taskDir -Filter "TASK-*.md" -ErrorAction SilentlyContinue
if ($tasks.Count -eq 0) { Write-Error "GATE FAILED: No task files found. Run #architect first."; exit 1 }
$incompleteTasks = $tasks | Where-Object { (Get-Content $_.FullName | Select-String '^status:') -notmatch 'complete' }
if ($incompleteTasks.Count -gt 0) {
  Write-Error "GATE FAILED: $($incompleteTasks.Count) task(s) are not yet complete:"
  $incompleteTasks | ForEach-Object { Write-Error "  - $($_.Name)" }
  exit 1
}
Write-Host "Gate passed: $($tasks.Count) tasks — all complete. Safe to wrap up."
```

> **If the gate fails**: stop immediately. List the incomplete tasks to the user and tell them to complete implementation before running `#wrapup` again. Do not attempt to work around the gate.

### Step 1: Identify the Feature
1. If given a REQ ID, locate all artifacts under `.forge/specs/REQ-xxx-*/` via the codebase tool.
2. If no REQ ID, infer from the current branch name or recent merge commits (run `git log --oneline --merges -10`).
3. Read the requirement spec, architecture doc (if any), and all task files (confirmed complete by the gate above).
4. **Detect repository mode** — read `.forge/config.yml`. If it declares more than one `repos:` entry, this is **cross-repo mode** — also read `pipeline-state.json` from the spec directory.

### Step 2: Commit, Push, and Merge

**Branch check FIRST** — never commit on `main`. Run `git branch --show-current`. If it reports `main`, create a feature branch first.

For each touched repo, run this sequence inside that repo's worktree:
1. Check `git status` and `git diff` for uncommitted changes.
2. **Pre-Commit Security Scan**: Execute the logic from `#security_scan`. Read the uncommitted diff and scan for hardcoded secrets, passwords, or tokens.
   - If potential secrets are found, **STOP** and present them to the user.
   - For each finding, let the user decide if it must be **fixed** or if it is a **false positive**.
   - Do NOT proceed to the commit step until all "fixed" items are resolved.
3. If there are no uncommitted changes, or after the security scan is cleared, stage and commit:
   ```bash
   git add <relevant files>
   git commit -m "feat(REQ-xxx): <summary>"
   ```
4. Push: `git push -u origin <branch>`
5. If no PR exists, create one: `gh pr create` with a summary of what shipped.
6. If CI checks exist, monitor: `gh run watch`.
7. **Rebase check**: run `git merge-base --is-ancestor origin/main HEAD`. If the branch is behind main, rebase:
   ```bash
   git rebase origin/main
   git push --force-with-lease
   ```
   If conflicts, STOP and surface to the user.
8. Verify PR is mergeable: `gh pr view <prUrl> --json mergeable,mergeStateStatus`
9. Merge: `gh pr merge <prUrl> --squash --delete-branch` (run from parent repo path, not worktree).
10. Pull main and clean up worktree:
   ```bash
   git checkout main && git pull
   git worktree remove <worktree-path>
   git fetch --prune
   ```

### Step 3: Update Copilot Forge Artifact Statuses
1. Set the requirement's frontmatter `status` to `complete`.
2. Set all task statuses to `complete`.
3. Update the `updated` date on all modified artifacts to today's date.
4. If any tasks were deferred or descoped, note them under a "Deferred" section in the requirement file.
5. If `pipeline-state.json` exists, update it: set `"completed": true` and add a final entry to `phaseHistory`.

### Step 4: Capture Knowledge

#### Architectural Decisions
- Review the implementation for any emergent architectural or technical decisions that were made *after* the initial design.
- For local or feature-specific tradeoffs, log them in the feature's `.forge/specs/REQ-xxx-*/architecture.md` under `## Decisions & Tradeoffs`.
- For global shifts (decisions that affect multiple repos or set a new reusable standard):
  - Draft a formal ADR in `.forge/knowledge/decisions/ADR-xxx-slug.md` using the template at `.forge/templates/adr-template.md`.
  - Determine the next ADR ID using the atomic counter at `.forge/.next-adr`:
    ```bash
    ADR_NUM=$(cat .forge/.next-adr 2>/dev/null || echo "1")
    echo $((ADR_NUM + 1)) > .forge/.next-adr
    ```
- Propose updates to `.forge/context/architecture.md` if existing patterns were modified or deprecated.

#### Assumptions Validated or Invalidated
- Review assumptions from the requirement spec.
- Log any validated, invalidated, or unresolved assumptions to `.forge/knowledge/assumptions/ASSUME-xxx-slug.md`.
- Determine the next ASSUME ID using the atomic counter at `.forge/.next-assume`:
  ```bash
  ASSUME_NUM=$(cat .forge/.next-assume 2>/dev/null || echo "1")
  echo $((ASSUME_NUM + 1)) > .forge/.next-assume
  ```

#### Lessons Learned
- Any surprises during implementation?
- Approaches that didn't work and why?
- Things that worked particularly well?
- Log notable lessons to `.forge/knowledge/lessons/LESSON-xxx-slug.md`.
- Use the lesson template from `.forge/templates/lesson-template.md`.
- **Filename format**: `LESSON-xxx-slug.md` only (no date prefixes, no bare numeric prefixes).
- Determine next LESSON ID using `.forge/.next-lesson`:
  ```bash
  LESSON_NUM=$(cat .forge/.next-lesson 2>/dev/null || echo "1")
  echo $((LESSON_NUM + 1)) > .forge/.next-lesson
  ```
- Include `domain`, `component`, and `tags` for future retrieval by `#spec`, `#architect`, `#reflect`, `#review`.

#### Convention Updates
- New conventions established? Propose updates to `.forge/context/conventions.md`.

#### Support Documentation
- **User-Centric Documentation**: Update or create user-facing support knowledge based on the completed requirement.
- **Filter Technical Noise**: This document is for end-users and support agents. Focus on:
  - **Features & Usage**: How does the user use the new functionality?
  - **User Value**: What problem does this solve for the user?
  - **Troubleshooting**: Common user errors or FAQs.
  - **STRICTLY OMIT**: Internal technical details, database schema changes, backend refactors, or infrastructure updates that do not change the user experience.
- Use the support template from `.forge/templates/support-template.md`.
- Save it to `.forge/knowledge/support/SUP-xxx-slug.md`.
- Determine the next SUP ID using the atomic counter at `.forge/.next-sup`:
  ```bash
  SUP_NUM=$(cat .forge/.next-sup 2>/dev/null || echo "1")
  echo $((SUP_NUM + 1)) > .forge/.next-sup
  ```

#### Manual QA Documentation
- Finalize the manual test guide based on the implementation. 
- Ensure it includes clear **Action -> Expected Result** steps and any necessary **CLI/Curl commands**.
- Use the template from `.forge/templates/manual-qa-template.md`.
- Save it to `.forge/knowledge/qa/QA-xxx-slug.md`.
- Determine the next QA ID using the atomic counter at `.forge/.next-qa`:
  ```bash
  QA_NUM=$(cat .forge/.next-qa 2>/dev/null || echo "1")
  echo $((QA_NUM + 1)) > .forge/.next-qa
  ```

### Step 5: Generate Ship Summary

**Single-repo template**:
```
## REQ-xxx: Feature Title

**Status**: Shipped
**Branch**: feat/REQ-xxx-slug
**PR**: #nn
**Merged**: YYYY-MM-DD

### What shipped
- [bullet points of user-facing or developer-facing changes]

### Key decisions
- [notable architectural or design decisions]

### Metrics
- Files changed: N
- Lines added/removed: +N / -N
- Tests added: N
- Est. input tokens: ~N,NNN  |  Est. output tokens: ~N,NNN  |  Est. total: ~N,NNN

### Deferred items
- [work explicitly postponed for future]

### Follow-up needed
- [remaining work, monitoring, or verification required]
```

**Cross-repo template** (replace single PR/Branch lines with a Repos table):
Add a `### Repos` table showing `| Repo | Branch | PR | Files | +/- |` for each touched repo.

### Step 5b: Capture Token Estimate

Run the token estimator to record the session's approximate token consumption:

```powershell
# From the repo root
.\token-estimate.ps1 -ReqId REQ-xxx -UpdatePipelineState
```

This will:
1. Scan all files loaded across each pipeline phase.
2. Compute input + output token estimates using the ~4 chars/token formula.
3. Write the breakdown to `pipeline-state.json` under `tokenEstimate`.
4. Print a phase-by-phase table to the terminal.

Copy the **Est. GRAND TOTAL** value into the `### Metrics` block of the ship summary above.

> **Note**: If `token-estimate.ps1` is not present in the repo root, run `#token-estimate REQ-xxx` in Copilot Chat instead for an inline estimate.

### Step 6: Deploy
Walk touched repos and deploy each deployable component. Read `.forge/config.yml` for stack and deploy config:
- **Cloud Run backends** (`stack.backends` includes `cloud-run`): confirm the deploy succeeded via `gcloud run services describe <service> --project=<gcp.production_project>`.
- **iOS** (`stack.frontends` includes `ios`): read `ios.deploy_targets` and `ios.deploy_command` from config. Run deploy command for every device in `deploy_targets`.
- **Infrastructure changes**: note that IaC apply (Terraform/etc.) is needed and confirm with user.
- If no deployable changes, skip this step.

### Step 7: Recommend Next Steps
- If deferred items exist: "Consider creating `#spec` for deferred items: [list]"
- If follow-up monitoring is needed: "Monitor [what] for [how long]"
- If conventions were updated: "Review `.forge/context/conventions.md` changes"
- Otherwise: "Feature complete. No follow-up needed."
