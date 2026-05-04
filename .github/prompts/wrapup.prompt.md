---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Close out a completed feature — commit, merge, deploy, capture knowledge, emit ship summary
---

# wrapup — Feature Completion Wrap-Up

You are closing out a completed feature after it has been merged. This skill ensures Copilot Forge artifacts are finalized, knowledge is captured, and the team has a clear summary of what shipped.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Target: [REQ-xxx ID — provided by the user]

## Instructions

### Step 1: Identify the Feature
1. If given a REQ ID, locate all artifacts under `.forge/specs/REQ-xxx-*/` via the codebase tool.
2. If no REQ ID, infer from the current branch name or recent merge commits (run `git log --oneline --merges -10`).
3. Read the requirement spec, architecture doc (if any), and all task files.
4. **Detect repository mode** — read `.forge/config.yml`. If it declares more than one `repos:` entry, this is **cross-repo mode** — also read `pipeline-state.json` from the spec directory.

### Step 2: Commit, Push, and Merge

**Branch check FIRST** — never commit on `main`. Run `git branch --show-current`. If it reports `main`, create a feature branch first.

For each touched repo, run this sequence inside that repo's worktree:
1. Check `git status` and `git diff` for uncommitted changes.
2. If there are uncommitted changes, stage and commit:
   ```bash
   git add <relevant files>
   git commit -m "feat(REQ-xxx): <summary>"
   ```
3. Push: `git push -u origin <branch>`
4. If no PR exists, create one: `gh pr create` with a summary of what shipped.
5. If CI checks exist, monitor: `gh run watch`.
6. **Rebase check**: run `git merge-base --is-ancestor origin/main HEAD`. If the branch is behind main, rebase:
   ```bash
   git rebase origin/main
   git push --force-with-lease
   ```
   If conflicts, STOP and surface to the user.
7. Verify PR is mergeable: `gh pr view <prUrl> --json mergeable,mergeStateStatus`
8. Merge: `gh pr merge <prUrl> --squash --delete-branch` (run from parent repo path, not worktree).
9. Pull main and clean up worktree:
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
- Were new patterns introduced? Propose an update to `.forge/context/architecture.md`.
- Were existing patterns modified or deprecated?

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

### Deferred items
- [work explicitly postponed for future]

### Follow-up needed
- [remaining work, monitoring, or verification required]
```

**Cross-repo template** (replace single PR/Branch lines with a Repos table):
Add a `### Repos` table showing `| Repo | Branch | PR | Files | +/- |` for each touched repo.

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
