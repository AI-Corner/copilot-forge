---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: End-to-end bug fix workflow — report, analyze, fix, verify, ship, knowledge capture
---

# bugfix — Bug Fix Workflow

You are fixing a bug using a streamlined workflow. Changes land via PR, ride the project's CI/CD pipeline, and aren't marked resolved until every declared deploy target is confirmed.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Bug report: [bug description or BUG-xxx ID — provided by the user]

## Prerequisites

Use the codebase tool to verify `.forge/bugs/` exists. If it doesn't, stop: "The `.forge/` structure hasn't been initialized. Run `#init` first."

Read `.forge/config.yml` and `.forge/context/conventions.md` via the codebase tool.
Read `.forge/templates/bug-template.md` (or `templates/bug-template.md` at the toolkit root).

## Instructions

### Phase 1: Report
1. If given a bug description (not a BUG ID), create a bug report:
   - Determine the next BUG ID using the atomic counter at `.forge/.next-bug`:
     ```bash
     BUG_NUM=$(cat .forge/.next-bug 2>/dev/null || echo "1")
     echo $((BUG_NUM + 1)) > .forge/.next-bug
     ```
   - Create `.forge/bugs/BUG-xxx-slug.md` using `.forge/templates/bug-template.md`.
   - Fill in: description, reproduction steps, expected vs actual behavior, environment.
   - Set status to `open`, severity based on impact.
   - **Cross-repo**: if `.forge/config.yml` declares siblings AND the fix likely lives in a sibling, add `repo: <sibling-id>` or `touched_repos: [<id>, <id>]` to the bug frontmatter.
2. If given a BUG ID, read the existing bug report.

### Phase 2: Analyze
1. Use the codebase tool to trace the bug — search for relevant code paths based on the bug description.
2. Trace the execution flow that triggers the bug.
3. Identify the root cause (not just symptoms).
4. Read the identified files to understand the context.
5. Document the root cause in the bug report's "Root Cause" section.
6. **Validate the analysis**: re-read affected code paths to confirm the root cause is correct. Check for secondary issues or edge cases. Adjust if needed.

### Phase 3: Fix
1. **Determine target repo**: if the bug's frontmatter has `repo:` naming a sibling, work in that sibling's path from `.forge/config.yml`. For `touched_repos: [...]`, make one commit per touched repo on a shared branch name.
2. Create the fix branch: `git checkout -b fix/bug-xxx-slug`
3. Implement the fix following project conventions from `.forge/context/conventions.md`.
4. Ensure the fix addresses the root cause, not just symptoms.
5. Update related test files if the fix changes behavior.

### Phase 4: Verify
1. Run the test suite: `npm test` (or equivalent).
2. If tests fail, fix and re-run.
3. Update the bug report (leave status as `open` for now — marked resolved only after merge + deploy in Phase 7):
   - Fill in "Resolution" section with what was changed and why
   - Fill in "Files Changed" section with specific file paths
   - Update the `updated` date
4. Present interim summary (root cause, fix, files changed, test results). Then continue to Phase 5.

### Phase 5: Ship — Create Pull Request(s)

For each touched repo:
1. Push the fix branch: `git push -u origin fix/bug-xxx-slug`
2. Create the PR with `gh pr create`:
   - **Title**: `fix(BUG-xxx): short description`
   - **Body**: Summary, Bug reference, Root Cause, Files Changed, Test Plan checkboxes
3. Wait for CI: `gh pr checks <prUrl>`. Never bypass with `--no-verify` or admin-merge.
4. In cross-repo mode: create primary repo's PR last so its body can link every sibling. Edit sibling PRs to add the Related PRs section.

### Phase 6: Canary Deploy (Optional)
Skip when:
- Fix is iOS-only, documentation-only, or otherwise non-deployable
- Bug severity is low/medium AND staging gate in CI/CD is sufficient

Run when:
- Fix touches a deployable backend service AND severity is high/critical

Invoke `#canary` for each affected service. If all canaries pass, continue. If any fails, halt and surface the failure.

### Phase 7: Wrapup — Merge, Deploy, Knowledge Capture

**Step 1 — Merge each PR**:
1. Verify mergeable: `gh pr view <prUrl> --json mergeable,mergeStateStatus`
2. If main has advanced, rebase: `git rebase origin/main && git push --force-with-lease`. Re-check CI.
3. Merge: `gh pr merge <prUrl> --squash --delete-branch`
4. In cross-repo mode, walk `touched_repos:` order (or `merge_order:` from config).

**Step 2 — Confirm deploys** (skip if project doesn't use Cloud Run):
For each touched service, verify the fix is deployed to both staging and production:
```bash
gcloud run services describe <service> \
  --project=<gcp.staging_project from config> \
  --region=<region from config> \
  --format="value(status.latestReadyRevisionName)"
```
Confirm staging and production both serve the new revision.

**iOS deploy** (only when `stack.frontends` includes `ios` AND iOS repo was touched):
Read `ios.deploy_targets` and `ios.deploy_command` from `.forge/config.yml`. Deploy to every device in `deploy_targets`.

**Step 3 — Update the bug report**:
- Set status to `resolved`
- Update the `updated` date
- Add a Deployment section noting staging + production revisions

**Step 4 — Capture knowledge** (NEVER skip):
Evaluate: did this bug reveal something a future implementer should know?
- A surprising failure mode, race condition, schema mismatch?
- A pattern or anti-pattern worth recording?
- A check that would have caught this earlier?

If yes, write a lesson to `.forge/knowledge/lessons/LESSON-xxx-slug.md`:
```bash
LESSON_NUM=$(cat .forge/.next-lesson 2>/dev/null || echo "1")
echo $((LESSON_NUM + 1)) > .forge/.next-lesson
```
Include `domain`, `component`, `tags`. Filename format: `LESSON-xxx-slug.md` only.

If the bug genuinely produced no useful lesson (one-line typo, etc.), say so explicitly.

**Step 5 — Clean up**:
```bash
git checkout main && git pull
git worktree remove <fix-worktree-path>   # if separate worktree was used
git branch -D fix/bug-xxx-slug
git fetch --prune
```

**Step 6 — Final ship summary**:
```
## BUG-xxx: Bug Title — Resolved

**Severity**: <severity>
**PR**: #nn
**Merged**: YYYY-MM-DD

### Root cause
- 1-2 lines

### Fix
- 1-2 lines

### Deployment
- Staging: <service> revision <hash> @ 100% traffic
- Production: <service> revision <hash> @ 100% traffic

### Lessons captured
- LESSON-xxx-slug.md — one-line hook
  (or "None — fix was straightforward and revealed no new pattern")
```

## Branch Naming
Use `fix/bug-xxx-slug`. In cross-repo bugs, use the same branch name in every touched repo.

## Commit Message Format
```
fix(BUG-xxx): short description of the fix
```
