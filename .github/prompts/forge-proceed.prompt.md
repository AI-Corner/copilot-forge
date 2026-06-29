---

## Step 0: Preflight + Create Worktree + Load Shared Context

**ALWAYS FIRST.**

1. **Preflight** — verify all prerequisite files exist (stop with a clear message if any are missing):
   - `.forge/context/project-overview.md` — run `#forge-init` if missing
   - `.forge/context/rules/architecture.rules.md` — run `#forge-init` if missing
   - `.forge/context/rules/conventions.rules.md` — run `#forge-init` if missing
   - `.forge/specs/REQ-xxx-*/requirement.md` — run `#forge-spec` if missing

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
   - `.forge/context/rules/architecture.rules.md`
   - `.forge/context/rules/conventions.rules.md`
   - `.forge/context/project-overview.md`
   - `.forge/specs/REQ-xxx-*/requirement.md`
   - `.forge/config.yml` (if present)

6. **Initialize `pipeline-state.json`** in the primary's spec directory.

After Step 0 completes: update `pipeline-state.json` — append `0` to `completedPhases`, set `currentPhase` to `1`.

---

## Phase 1: Validate the Requirement Spec

**Gate**: `currentPhase` must be `1`. After completion: append `1`, set `currentPhase=2`.

Run the `#forge-validate` checklist inline for the spec phase:
1. If **APPROVED**: set requirement status to `approved` and move to Phase 2.
2. If **NEEDS REVISION**: fix all FAIL items, then re-validate (up to 3 loops).

**Log**: "Spec validated and approved." Continue to Phase 2 immediately.

---

## Phase 2: Architect & Break Into Tasks

**Gate**: `currentPhase` must be `2`. After completion: append `2`, set `currentPhase=3`.

Run the `#forge-architect` prompt inline:
1. Invoke the architect workflow — reads context, designs architecture, creates task files with dependencies.
2. In cross-repo mode: every generated task's frontmatter must include a `repo:` field.
3. **Reconcile touched repos**: after architect returns, scan task files for distinct `repo:` values. Update `pipeline-state.json` — set `touched: true` for repos with tasks, `touched: false` for repos with no tasks.

**Log**: Emit a one-paragraph summary of the architecture and task dependency graph. Continue to Phase 3 immediately.

---

## Phase 3: Validate Architecture & Tasks

**Gate**: `currentPhase` must be `3`. After completion: append `3`, set `currentPhase=4`.

Run the `#forge-validate` checklist inline for the architecture + tasks phase (up to 3 loops).

**Log**: "Architecture and tasks validated." Continue to Phase 3.5 immediately.

---

## Phase 3.5: Test-Driven Development (TDD)

**Gate**: `currentPhase` must be `3.5`. After completion: append `3.5`, set `currentPhase=4`.

Run the `#forge-tdd` prompt inline:
1. Generate the failing test suite based on the requirement and tasks.
2. Verify tests fail for the right reasons (the "Red" phase).

**Log**: Emit a summary of the failing test suite. Continue to Phase 4 immediately.

---

## Phase 4: Implement

**Gate**: `currentPhase` must be `4`. After completion: append `4`, set `currentPhase=5`.

**Execute tasks one at a time in dependency order** (reference: `#agents/task-implementer`). All work happens inside the feature branch worktree:

1. Build the dependency graph from task frontmatter.
2. On resume: read `pipeline-state.json` — skip tasks in `phase4.completedTasks`; resume `phase4.currentTask` if non-null.
3. For each task (in dependency order):
   - Write `phase4.currentTask` to the TASK-xxx ID before starting.
   - **Refresh context**: run `.\scripts\forge-context.ps1 -ReqId REQ-xxx -TaskId TASK-xxx` to regenerate `.forge/.active-context.md`. Read this file before touching any code.
   - Read the task file for requirements, files to modify, ACs, and `repo:` field.
   - All file reads/writes, tests, and git operations happen inside the worktree (use `git -C <worktree>` form).
   - Implement the changes following project conventions from `.forge/context/rules/conventions.rules.md`.
   - Write any additional tests as specified in the task (if not covered by Phase 3.5 TDD).
   - Run the test suite: `.\scripts\forge-test.ps1 -ReqId REQ-xxx`. Read `.forge/.last-test-run.md` to verify previously failing TDD tests now pass (the "Green" phase).
   - Mark the task status as `complete` in its frontmatter.
   - Commit inside the worktree: `feat(scope): description [TASK-xxx]`
   - Append the TASK-xxx ID to `phase4.completedTasks` and clear `phase4.currentTask`.
   - **Drift check**: If `phase4.completedTasks.length % 3 === 0`, run `#forge-check-drift` inline to catch convention drift early. If any 🔴 IRON LAW violations are found, fix them before continuing to the next task. 🟡 GOLDEN PATH and 🔵 RULE findings are logged but do not block progress.

**Log**: After each task completes, emit one line: `TASK-xxx ✓`. Continue immediately to the next task.

---

## Phase 5: Verify (Computational & Inferential)

**Gate**: `currentPhase` must be `5`. After completion: append `5`, set `currentPhase=6`.

**Part 1: Computational Verification**
Run all deterministic computational sensors sequentially:
1. **Lint Gate** (`#agents/computational/lint-gate`): Run configured linter.
2. **Typecheck Gate** (`#agents/computational/typecheck-gate`): Run type checker.
3. **Build Gate** (`#agents/computational/build-gate`): Ensure the project builds.
4. **Test Gate** (`#agents/computational/test-gate`): Run the full test suite.
5. **Secret Scan Gate** (`#agents/computational/secret-scan`): Scan diff for hardcoded credentials.
6. **Vuln Scan Gate** (`#agents/computational/vuln-scan`): Scan for dependency vulnerabilities.

**Computational Gate Rule**: If *any* computational sensor fails, you must STOP, fix the underlying code issue, and re-run the failed computational sensors until they pass. **Do not proceed to Part 2 until Part 1 is 100% clean.**

**Part 2: Inferential Verification**
Only after a clean computational pass, use the LLM-driven reviewers to verify heuristics.
**Get diffs**: run `git -C <worktree> diff main...HEAD` plus the list of changed files.

**Run review checklists sequentially**:
**Step A — Spec Adherence** (reference: `#agents/inferential/spec-adherence`): strictly compare diff against ACs.
**Step B — Self-Review** (reference: `#agents/reflector`):
Run the reflector checklist: edge cases handled, naming conventions, proper layering, lessons from `.forge/knowledge/lessons/`.
**Step C — Correctness** (reference: `#agents/inferential/correctness-reviewer`): logic errors, null handling, race conditions.
**Step D — Quality** (reference: `#agents/inferential/quality-reviewer`): convention compliance, duplication.
**Step E — Architecture** (reference: `#agents/inferential/architecture-reviewer`): API contract compliance, layer bounds.
**Step F — Test Quality** (reference: `#agents/inferential/test-auditor`): coverage gaps, mock completeness.
**Step G — Security** (reference: `#agents/inferential/security-auditor`): injection risks, auth bypass.

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

Run the `#forge-canary` prompt for each affected deployable service. If any canary fails, halt (legitimate halt #3).

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
7. Run `#forge-wrapup REQ-xxx` to capture knowledge and emit ship summary.
8. Set `"completed": true` in `pipeline-state.json`.

**Terminal claim** (required — pipeline complete report must lead with exactly one of):
- `merged` — all PRs merged, verified via `gh pr view --json state,mergedAt`
- `pr-ready` — PRs open and CI green, awaiting manual merge
- `blocked` — human input needed
- `failed` — pipeline failed past automatic recovery

---

## Error Handling — Failure Taxonomy

Every failure the agent encounters must map to exactly one of these four actions. No ambiguous failures.

| Failure Type | Action | Max Retries | Example |
|---|---|---|---|
| **Transient** | Auto-retry | 3 | Build flake, network timeout, test flake |
| **Spec Ambiguity** | Pause and ask user | 0 | Missing acceptance criteria, contradictory requirements |
| **Artifact Corruption** | Regenerate artifact, log to `metrics.gateFailures` | 1 | Bad frontmatter, missing task file, invalid status |
| **Unrecoverable** | Abort phase, surface error with remediation | 0 | Gate failure, security scan failure, merge conflict |

### Specific rules
- **Test failures during implementation**: classify as **Transient**. Auto-retry up to 2 fix attempts. If still failing, reclassify as **Spec Ambiguity** and ask the user.
- **Validation stuck after 3 loops**: classify as **Spec Ambiguity**. Present remaining FAIL items and halt.
- **Missing context files**: classify as **Unrecoverable**. Tell the user to run `#forge-init` first.
- **Merge conflicts**: classify as **Unrecoverable**. Stop and ask the user how to resolve.

### Metric logging
After every phase completes, update `metrics` in `pipeline-state.json`:
- `phaseTimings["<phase>"]`: duration in milliseconds
- `retryCount`: increment for each auto-retry within a phase
**Gate**: `currentPhase` must be `1`. After completion: append `1`, set `currentPhase=2`.

Run the `#forge-validate` checklist inline for the spec phase:
1. If **APPROVED**: set requirement status to `approved` and move to Phase 2.
2. If **NEEDS REVISION**: fix all FAIL items, then re-validate (up to 3 loops).

**Log**: "Spec validated and approved." Continue to Phase 2 immediately.

---

## Phase 2: Architect & Break Into Tasks

**Gate**: `currentPhase` must be `2`. After completion: append `2`, set `currentPhase=3`.

Run the `#forge-architect` prompt inline:
1. Invoke the architect workflow — reads context, designs architecture, creates task files with dependencies.
2. In cross-repo mode: every generated task's frontmatter must include a `repo:` field.
3. **Reconcile touched repos**: after architect returns, scan task files for distinct `repo:` values. Update `pipeline-state.json` — set `touched: true` for repos with tasks, `touched: false` for repos with no tasks.

**Log**: Emit a one-paragraph summary of the architecture and task dependency graph. Continue to Phase 3 immediately.

---

## Phase 3: Validate Architecture & Tasks

**Gate**: `currentPhase` must be `3`. After completion: append `3`, set `currentPhase=4`.

Run the `#forge-validate` checklist inline for the architecture + tasks phase (up to 3 loops).

**Log**: "Architecture and tasks validated." Continue to Phase 3.5 immediately.

---

## Phase 3.5: Test-Driven Development (TDD)

**Gate**: `currentPhase` must be `3.5`. After completion: append `3.5`, set `currentPhase=4`.

Run the `#forge-tdd` prompt inline:
1. Generate the failing test suite based on the requirement and tasks.
2. Verify tests fail for the right reasons (the "Red" phase).

**Log**: Emit a summary of the failing test suite. Continue to Phase 4 immediately.

---

## Phase 4: Implement

**Gate**: `currentPhase` must be `4`. After completion: append `4`, set `currentPhase=5`.

**Execute tasks one at a time in dependency order** (reference: `#agents/task-implementer`). All work happens inside the feature branch worktree:

1. Build the dependency graph from task frontmatter.
2. On resume: read `pipeline-state.json` — skip tasks in `phase4.completedTasks`; resume `phase4.currentTask` if non-null.
3. For each task (in dependency order):
   - Write `phase4.currentTask` to the TASK-xxx ID before starting.
   - **Refresh context**: run `.\scripts\forge-context.ps1 -ReqId REQ-xxx -TaskId TASK-xxx` to regenerate `.forge/.active-context.md`. Read this file before touching any code.
   - Read the task file for requirements, files to modify, ACs, and `repo:` field.
   - All file reads/writes, tests, and git operations happen inside the worktree (use `git -C <worktree>` form).
   - Implement the changes following project conventions from `.forge/context/rules/conventions.rules.md`.
   - Write any additional tests as specified in the task (if not covered by Phase 3.5 TDD).
   - Run the test suite: `.\scripts\forge-test.ps1 -ReqId REQ-xxx`. Read `.forge/.last-test-run.md` to verify previously failing TDD tests now pass (the "Green" phase).
   - Mark the task status as `complete` in its frontmatter.
   - Commit inside the worktree: `feat(scope): description [TASK-xxx]`
   - Append the TASK-xxx ID to `phase4.completedTasks` and clear `phase4.currentTask`.
   - **Drift check**: If `phase4.completedTasks.length % 3 === 0`, run `#forge-check-drift` inline to catch convention drift early. If any 🔴 IRON LAW violations are found, fix them before continuing to the next task. 🟡 GOLDEN PATH and 🔵 RULE findings are logged but do not block progress.

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

Run the `#forge-canary` prompt for each affected deployable service. If any canary fails, halt (legitimate halt #3).

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
7. Run `#forge-wrapup REQ-xxx` to capture knowledge and emit ship summary.
8. Set `"completed": true` in `pipeline-state.json`.

**Terminal claim** (required — pipeline complete report must lead with exactly one of):
- `merged` — all PRs merged, verified via `gh pr view --json state,mergedAt`
- `pr-ready` — PRs open and CI green, awaiting manual merge
- `blocked` — human input needed
- `failed` — pipeline failed past automatic recovery

---

## Error Handling — Failure Taxonomy

Every failure the agent encounters must map to exactly one of these four actions. No ambiguous failures.

| Failure Type | Action | Max Retries | Example |
|---|---|---|---|
| **Transient** | Auto-retry | 3 | Build flake, network timeout, test flake |
| **Spec Ambiguity** | Pause and ask user | 0 | Missing acceptance criteria, contradictory requirements |
| **Artifact Corruption** | Regenerate artifact, log to `metrics.gateFailures` | 1 | Bad frontmatter, missing task file, invalid status |
| **Unrecoverable** | Abort phase, surface error with remediation | 0 | Gate failure, security scan failure, merge conflict |

### Specific rules
- **Test failures during implementation**: classify as **Transient**. Auto-retry up to 2 fix attempts. If still failing, reclassify as **Spec Ambiguity** and ask the user.
- **Validation stuck after 3 loops**: classify as **Spec Ambiguity**. Present remaining FAIL items and halt.
- **Missing context files**: classify as **Unrecoverable**. Tell the user to run `#forge-init` first.
- **Merge conflicts**: classify as **Unrecoverable**. Stop and ask the user how to resolve.

### Metric logging
After every phase completes, update `metrics` in `pipeline-state.json`:
- `phaseTimings["<phase>"]`: duration in milliseconds
- `retryCount`: increment for each auto-retry within a phase
- `gateFailures`: increment for each `.\scripts\forge-gate.ps1` failure
- `driftEvents`: increment when the agent detects it referenced stale context
- `forcedTransitions`: append an entry when `--Force` is used

## Internal Reference
- **Incoming Skill Dependencies**: `#forge-sprint`
- **Incoming Agent Dependencies**: *None*
- **Outgoing Skill Dependencies**: `#forge-architect`, `#forge-canary`, `#forge-check-drift`, `#forge-reflect`, `#forge-review`, `#forge-tdd`, `#forge-validate`, `#forge-wrapup`
- **Outgoing Agent Dependencies**: `#agents/reflector`, `#agents/task-implementer`
- **Resource Dependencies**: `forge-gate.ps1`
