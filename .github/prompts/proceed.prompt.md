---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: End-to-end pipeline — validate spec → architect → tdd → implement → reflect → review → PR → wrapup for a single REQ
---

# proceed — Full Copilot Forge pipeline

You are an autonomous Copilot Forge orchestrator. Given a requirement number (REQ-xxx), you drive it from validated spec all the way to a pull request — validating at each gate, fixing issues automatically, and only pausing when stuck or needing human input.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
>
> **Copilot difference**: All phases run sequentially in your own context. There is no parallel agent dispatch. At Phase 4, implement tasks one at a time in dependency order. At Phase 5, run all review checklists sequentially. Reference `.github/prompts/agents/*.prompt.md` for the full checklists used in each dimension.

## Autonomous Execution Contract

This prompt is an **autonomous orchestrator**. It runs end-to-end without human input except at these **five** legitimate halt points:

1. **Validation fails 3 times at any gate** (Phase 1 or Phase 3) — surface blockers.
2. **Reflector surfaces user-facing questions** (Phase 5) — surface as numbered list and wait.
3. **Canary deploy fails** (Phase 7.5) — surface failure and wait for direction.
4. **Merge conflicts during rebase** (Phase 8) — surface conflicts and wait.
5. **Staging CI timeout** (Phase 8a, if `pipeline.snapshot_promotion: true`) — surface and wait.

For everything else, continue immediately. Don't phrase log lines as questions.

## Arguments

The user provides a requirement ID, e.g., `#proceed REQ-023`.
- Normalize to `REQ-xxx` format (zero-pad to 3 digits)
- Locate the spec at `.forge/specs/REQ-xxx-*/requirement.md`
- If the spec doesn't exist, stop and tell the user to run `#spec` first

## Pipeline State Tracking

Maintain a state file at `.forge/specs/REQ-xxx-*/pipeline-state.json` to track pipeline progress across all phases. Schema:

```json
{
  "req": "REQ-xxx",
  "branch": "feat/REQ-xxx-short-description",
  "startedAt": "ISO-timestamp",
  "completed": false,
  "currentPhase": 0,
  "completedPhases": [],
  "phaseHistory": [],
  "repos": {
    "<repo-id>": {
      "primary": true,
      "path": "/absolute/path/to/repo",
      "worktree": "/absolute/path/to/.worktrees/REQ-xxx",
      "branch": "feat/REQ-xxx-short-description",
      "touched": true,
      "prUrl": null,
      "merged": false
    }
  },
  "mergeOrder": ["<repo-id>"],
  "phase4": {
    "currentTask": null,
    "completedTasks": [],
    "failedTasks": []
  }
}
```

Before starting any phase: read the state file and verify `currentPhase` matches. After completing any phase: update `completedPhases` and `currentPhase`. If the state file already exists, resume from `currentPhase`.

---

## Step 0: Preflight + Create Worktree + Load Shared Context

**ALWAYS FIRST.**

1. **Preflight** — verify all prerequisite files exist (stop with a clear message if any are missing):
   - `.forge/context/project-overview.md` — run `#init` if missing
   - `.forge/context/architecture.md` — run `#init` if missing
   - `.forge/context/conventions.md` — run `#init` if missing
   - `.forge/specs/REQ-xxx-*/requirement.md` — run `#spec` if missing

2. **Resolve repo registry** — read `.forge/config.yml`. If absent, use single-repo mode (one repo, the current workspace).

3. **Create a git worktree** for the feature branch:
   ```bash
   git worktree add .worktrees/REQ-xxx feat/REQ-xxx-short-description
   ```
   Check for collision first: `git worktree list --porcelain`. If the target path is already registered to the same branch, treat as resume (skip add). If registered to a different branch, halt and tell the user to clean up.

4. **Pull main** to ensure it's up to date:
   ```bash
   git checkout main && git pull
   ```

5. **Load shared context** via the codebase tool — read these into conversation once:
   - `.forge/context/architecture.md`
   - `.forge/context/conventions.md`
   - `.forge/context/project-overview.md`
   - `.forge/specs/REQ-xxx-*/requirement.md`
   - `.forge/config.yml` (if present)

6. **Initialize `pipeline-state.json`** in the primary's spec directory.

After Step 0 completes: update `pipeline-state.json` — append `0` to `completedPhases`, set `currentPhase` to `1`.

---

## Phase 1: Validate the Requirement Spec

**Gate**: `currentPhase` must be `1`. After completion: append `1`, set `currentPhase=2`.

Run the `#validate` checklist inline for the spec phase:
1. If **APPROVED**: set requirement status to `approved` and move to Phase 2.
2. If **NEEDS REVISION**: fix all FAIL items, then re-validate (up to 3 loops).

**Log**: "Spec validated and approved." Continue to Phase 2 immediately.

---

## Phase 2: Architect & Break Into Tasks

**Gate**: `currentPhase` must be `2`. After completion: append `2`, set `currentPhase=3`.

Run the `#architect` prompt inline:
1. Invoke the architect workflow — reads context, designs architecture, creates task files with dependencies.
2. In cross-repo mode: every generated task's frontmatter must include a `repo:` field.
3. **Reconcile touched repos**: after architect returns, scan task files for distinct `repo:` values. Update `pipeline-state.json` — set `touched: true` for repos with tasks, `touched: false` for repos with no tasks.

**Log**: Emit a one-paragraph summary of the architecture and task dependency graph. Continue to Phase 3 immediately.

---

## Phase 3: Validate Architecture & Tasks

**Gate**: `currentPhase` must be `3`. After completion: append `3`, set `currentPhase=4`.

Run the `#validate` checklist inline for the architecture + tasks phase (up to 3 loops).

**Log**: "Architecture and tasks validated." Continue to Phase 3.5 immediately.

---

## Phase 3.5: Test-Driven Development (TDD)

**Gate**: `currentPhase` must be `3.5`. After completion: append `3.5`, set `currentPhase=4`.

Run the `#tdd` prompt inline:
1. Generate the failing test suite based on the requirement and tasks.
2. Verify tests fail for the right reasons (the "Red" phase).

**Log**: Emit a summary of the failing test suite. Continue to Phase 4 immediately.

---

## Phase 4: Implement

**Gate**: `currentPhase` must be `4`. After completion: append `4`, set `currentPhase=5`.

**Execute tasks one at a time in dependency order** (all work happens inside the feature branch worktree):

1. Build the dependency graph from task frontmatter.
2. On resume: read `pipeline-state.json` — skip tasks in `phase4.completedTasks`; resume `phase4.currentTask` if non-null.
3. For each task (in dependency order):
   - Write `phase4.currentTask` to the TASK-xxx ID before starting.
   - Read the task file for requirements, files to modify, ACs, and `repo:` field.
   - All file reads/writes, tests, and git operations happen inside the worktree (use `git -C <worktree>` form).
   - Implement the changes following project conventions from `.forge/context/conventions.md`.
   - Write any additional tests as specified in the task (if not covered by Phase 3.5 TDD).
   - Run the test suite: `npm test` or equivalent. Ensure the previously failing TDD tests now pass (the "Green" phase).
   - Mark the task status as `complete` in its frontmatter.
   - Commit inside the worktree: `feat(scope): description [TASK-xxx]`
   - Append the TASK-xxx ID to `phase4.completedTasks` and clear `phase4.currentTask`.

**Log**: After each task completes, emit one line: `TASK-xxx ✓`. Continue immediately to the next task.

---

## Phase 5: Verify (Reflect + Review)

**Gate**: `currentPhase` must be `5`. After completion: append `5`, set `currentPhase=6`.

**Get diffs**: run `git -C <worktree> diff main...HEAD` plus the list of changed files.

**Run review checklists sequentially** (reference the full checklists in `.github/prompts/agents/`):

**Step A — Self-Review** (reference: `#agents/reflector`):
Run the reflector checklist:
- Does the code do what the requirement specifies? Are all ACs met?
- Edge cases handled? Follows naming conventions? Proper layering?
- New code has tests? Tests cover error paths?
- No TODOs, commented-out code, or debug logging?
- Check `.forge/knowledge/lessons/` for applicable pitfalls.

**Step B — Correctness** (reference: `#agents/correctness-reviewer`): logic errors, null handling, race conditions, error handling, security.

**Step C — Quality** (reference: `#agents/quality-reviewer`): convention compliance, naming, duplication, input validation.

**Step D — Architecture** (reference: `#agents/architecture-reviewer`): layering, test coverage, mock completeness, API contract compliance.

**Step E — Test Coverage** (reference: `#agents/test-auditor`): coverage gaps, mock completeness, test quality.

**Step F — Security** (reference: `#agents/security-auditor`): injection, auth bypass, data exposure, rate limiting.

**Consolidate**: deduplicate overlapping findings. Produce a single ranked list by severity.

**Fix in one pass**:
1. Critical + must-fix Major: fix immediately, run tests, commit with `fix(scope): address verify finding [REQ-xxx]`.
2. Should-fix Minor: fix unless significant refactor — note as follow-up otherwise.
3. Nit/observation: fix trivial ones, skip the rest.

**User-facing questions from reflector**: surface as a numbered list and wait (legitimate halt #2).

**Log**: Emit combined verify summary. If reflector surfaced questions, halt here. Otherwise continue to Phase 6.

---

## Phase 6: Create Pull Request(s)

**Gate**: `currentPhase` must be `6`. After completion: append `6`, set `currentPhase=7`.

1. For each touched repo, push the feature branch from its worktree:
   ```bash
   git -C <worktree> push -u origin feat/REQ-xxx-short-description
   ```
2. Set the requirement status to `complete` in its frontmatter (primary repo only).
3. Create a PR using `gh pr create`:
   - **Title**: `feat: short description [REQ-xxx]`
   - **Body**: Summary (2-3 bullets), Requirement, Tasks Completed (checkboxes), Architecture Decisions, Test Coverage, Reflection Notes
4. Write the PR URL to `repos[id].prUrl` in `pipeline-state.json`.
5. Report PR URL to the user.

---

## Phase 7: PR Cleanup & CI

**Gate**: `currentPhase` must be `7`. After completion: append `7`, set `currentPhase=7.5` or `8`.

1. Review the PR diff: `gh pr diff <prUrl>`
2. Check for:
   - Stray debug logs, TODOs, commented-out code
   - Files that shouldn't be included (secrets, generated files)
   - Commit message consistency
   - PR description accuracy
3. If issues found: fix in the worktree, commit with `fix(scope): PR cleanup [REQ-xxx]`, push.
4. If CI checks are configured: `gh pr checks <prUrl>`. Wait for in-flight checks.

**Log**: "Clean, CI green." Continue to Phase 7.5 or Phase 8 immediately.

---

## Phase 7.5: Canary Deploy (Optional)

Only run if the requirement's frontmatter includes `deployable: true` OR changes include deployable service code. Skip if `deployable: false` or iOS-only/docs-only changes.

Run the `#canary` prompt for each affected deployable service. If any canary fails, halt (legitimate halt #3).

**Log**: Canary results. On all-pass, continue to Phase 8 immediately.

---

## Phase 8: Wrapup

**Gate**: `currentPhase` must be `8`. After completion: set `"completed": true`.

**Merge and clean up**:
1. Verify the PR is mergeable: `gh pr view <prUrl> --json mergeable,mergeStateStatus`
2. If main has advanced, rebase: `git -C <worktree> rebase origin/main && git push --force-with-lease`
3. Merge: `gh pr merge <prUrl> --squash --delete-branch` (run from parent repo path, not worktree — git refuses to delete a branch checked out in a worktree).
4. Set `repos[id].merged = true` in `pipeline-state.json`.
5. Pull main: `git checkout main && git pull`
6. Remove worktree: `git worktree remove <worktree-path>` (use the absolute path from state).
7. Run `#wrapup REQ-xxx` to capture knowledge and emit ship summary.
8. Set `"completed": true` in `pipeline-state.json`.

**Terminal claim** (required — pipeline complete report must lead with exactly one of):
- `merged` — all PRs merged, verified via `gh pr view --json state,mergedAt`
- `pr-ready` — PRs open and CI green, awaiting manual merge
- `blocked` — human input needed
- `failed` — pipeline failed past automatic recovery

---

## Error Handling

- **Test failures during implementation**: stop, diagnose, fix in the worktree, re-run tests before continuing. If unfixable after 2 attempts, pause and ask the user.
- **Validation stuck after 3 loops**: present remaining FAIL items and ask the user.
- **Missing context files**: tell the user to run `#init` first.
- **Merge conflicts**: stop and ask the user how to resolve.
