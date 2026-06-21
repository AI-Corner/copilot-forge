# Copilot Forge — Prompt Usage Guide

Complete reference for every Copilot Forge prompt. Each section covers **what the prompt does**, **when to call it**, **what it expects as input**, **what it produces**, and **where it fits in the workflow**.

> **How to invoke**: Type `#<prompt-name>` in GitHub Copilot Chat (e.g., `#init`, `#spec`, `#learn`).

---

## Quick Reference

| Prompt | Category | One-Liner |
|--------|----------|-----------|
| [`#init`](#init) | Setup | Bootstrap `.forge/` in a new repo |
| [`#spec`](#spec) | Planning | Write a requirement spec from a feature request |
| [`#architect`](#architect) | Planning | Design architecture and break a requirement into tasks |
| [`#validate`](#validate) | Quality Gate | Validate any phase output before advancing |
| [`#tdd`](#tdd) | Testing | Generate failing test suites before implementation |
| [`#proceed`](#proceed) | Orchestration | Run the full pipeline end-to-end for a single REQ |
| [`#sprint`](#sprint) | Orchestration | Batch-run multiple `#proceed` pipelines sequentially |
| [`#check-drift`](#check-drift) | Review | Lightweight read-only convention compliance check |
| [`#reflect`](#reflect) | Review | Post-implementation self-review before formal review |
| [`#review`](#review) | Review | Multi-dimension code review |
| [`#bugfix`](#bugfix) | Bug Fixing | End-to-end bug fix workflow |
| [`#vibe`](#vibe) | Lightweight | Fast, low-overhead workflow for trivial changes |
| [`#query`](#query) | Knowledge | Query project knowledge and optionally capture new insights |
| [`#wrapup`](#wrapup) | Completion | Close out a feature — merge, deploy, capture knowledge |
| [`#canary`](#canary) | Deployment | Canary deploy with smoke tests |
| [`#deploy`](#deploy) | Deployment | Execute deployment steps from deployment config |
| [`#issue_epic_creation`](#issue_epic_creation) | Integration | Sync REQs and Tasks to GitLab as Epics and Issues |
| [`#status`](#status) | Visibility | Show current state of all Copilot Forge work |
| [`#analyze`](#analyze) | Health | Codebase health audit |
| [`#security_scan`](#security_scan) | Security | Pre-commit secret and credential audit |
| [`#forge-admin`](#forge-admin) | Maintenance | Modify the Forge toolkit safely |
| [`#template-drift`](#template-drift) | Maintenance | Detect drift between local and canonical templates |
| [`#token-estimate`](#token-estimate) | Metrics | Estimate token consumption per pipeline phase |
| [`#synthesize`](#synthesize) | Knowledge | Process learning inbox into permanent rules/lessons/ADRs |
| [`#prune`](#prune) | Knowledge | Periodic knowledge hygiene — archive stale rules and lessons |

---

## Workflow Map

The standard Copilot Forge workflow is:

```
#init → #spec → #validate → #architect → #validate → #tdd → implement → #reflect → #review → merge → #wrapup → #synthesize (periodically)
```

Or automated via `#proceed` (single REQ) or `#sprint` (batch):

```
#proceed REQ-xxx     ← runs all phases automatically
#sprint REQ-001 REQ-002 REQ-003   ← runs #proceed for each REQ sequentially
```

Standalone utilities can be invoked at any time:

```
#query       — query project knowledge and optionally capture new insights
#bugfix      — fix a bug end-to-end
#vibe        — quick change without heavy specs
#check-drift — lightweight read-only convention compliance check
#analyze     — codebase health audit
#optimize    — performance scanner
#status      — see what's in progress
#canary      — canary deploy with smoke tests
#security_scan — scan for secrets before committing
#forge-admin — modify the Forge toolkit itself safely
#template-drift — check template freshness
#token-estimate — estimate session token cost
#synthesize  — process learning inbox into permanent knowledge
#prune       — archive stale rules and lessons
```

---

## Setup

### `#init`

> Bootstrap the `.forge/` directory structure in a new project repo.

| | |
|---|---|
| **When to call** | Once per project, at the very beginning. Also useful to fill gaps if `.forge/` was partially initialized. |
| **Input** | Optional: target directory path. Defaults to workspace root. |
| **Prerequisites** | None — this is the first prompt you run. |
| **What it does** | 1. Gathers project context (name, description, tech stack, scope, patterns) — auto-extracts from `README.md` and `package.json` if present.<br>2. **Migration check** — if a legacy `.forge/context/architecture.md` exists, auto-migrates to the v2 layout (`rules/` + `corpus/`).<br>3. Creates the full `.forge/` directory tree: `context/` (with `rules/` and `corpus/` subdirectories), `specs/`, `bugs/`, `knowledge/` (with `inbox/` and `archive/`), `templates/`.<br>4. Populates context files: `project-overview.md`, `taxonomy.md`, `corpus/architecture.md`, `corpus/conventions.md`, `corpus/variables.md`, `corpus/deployment.md`, and distilled `rules/*.rules.md` files.<br>5. **Empirical State** — Generates `codebase-state.md` (tool/framework versions) and scaffolds `quality-radar.md` and `code-debt.md`.<br>6. Copies templates from the toolkit's canonical `templates/` directory.<br>7. Scans for CI/CD configurations and populates `corpus/deployment.md`.<br>8. Scans for environment variables and populates `corpus/variables.md`.<br>9. Updates `.gitignore` with Copilot Forge exclusions.<br>10. Optionally scaffolds cross-repo `config.yml` and local secrets. |
| **Outputs** | Complete `.forge/` directory structure ready for spec-driven development. |
| **Next step** | `#spec` to write your first requirement. |

---

## Planning

### `#spec`

> Write a requirement specification from a feature request using the Zachman 5W1H Framework.

| | |
|---|---|
| **When to call** | When you have a new feature request, user story, or enhancement idea that needs to be formally specified before implementation. |
| **Input** | Feature request description in natural language. |
| **Prerequisites** | `.forge/` must be initialized (`#init`). |
| **What it does** | 1. **Workflow routing** — evaluates the request against 7 criteria (cross-boundary impact, DB changes, security, infrastructure, testability, ambiguity, unit tests). If ALL are NO, suggests `#vibe` instead.<br>2. **Architectural interview** — asks clarifying questions mapped to the Zachman 5W1H framework (What, Who, When, Where, Why, How) if the request is vague.<br>3. **Retrieval** — searches `.forge/knowledge/lessons/`, existing specs, and resolved bugs for relevant prior context. Scores candidates by component/domain/tags match and surfaces the top 5.<br>4. **Spec authoring** — creates `REQ-xxx-slug/requirement.md` with frontmatter, all 6 Zachman sections, acceptance criteria, assumptions, open questions, out-of-scope items, and retrieved context citations.<br>5. **ID management** — reads/increments `.forge/.next-req` counter. |
| **Outputs** | `.forge/specs/REQ-xxx-slug/requirement.md` — the formal spec document. |
| **Next step** | `#validate` to verify the spec, then `#architect` to design and break into tasks. |

---

### `#architect`

> Design architecture for a requirement and break it into implementable tasks.

| | |
|---|---|
| **When to call** | After a requirement spec has been written and validated. |
| **Input** | `REQ-xxx` ID or requirement description. |
| **Prerequisites** | `.forge/context/architecture.md` and `conventions.md` must exist. The requirement must have `status: draft` or `approved`. |
| **What it does** | 1. **Context loading** — reads the requirement spec, existing architecture, conventions, prior ADRs, assumptions, and matching lessons from `.forge/knowledge/`.<br>2. **Codebase exploration** — traces similar implementations, maps affected layers and files, identifies integration surfaces and extension points.<br>3. **Architecture design** — creates `architecture.md` with approach, Mermaid diagrams (sequence/flowchart), execution flow breakdown, data model changes, API changes, environment/config needs, and decisions & tradeoffs.<br>4. **Task breakdown** — creates `TASK-xxx-slug.md` files in dependency order (data layer → service → routes → UI). Each task has frontmatter, description, files to create/modify, acceptance criteria, and technical notes.<br>5. **Cross-repo support** — in cross-repo mode, every task gets a `repo:` field. No single task modifies files in multiple repos.<br>6. **ADR promotion** — if any decision affects multiple features/repos, drafts a standalone ADR in `.forge/knowledge/decisions/`.<br>7. **Mandatory tasks** — always creates tasks for user documentation updates and manual QA guide drafting. |
| **Outputs** | Architecture doc + ordered task files under `.forge/specs/REQ-xxx-slug/tasks/`. |
| **Next step** | `#validate` to verify architecture and tasks. |

---

## Quality Gates

### `#validate`

> Validate any Copilot Forge phase output before advancing to the next phase.

| | |
|---|---|
| **When to call** | After completing any phase — spec, architecture, tasks, or implementation — before moving to the next. |
| **Input** | `REQ-xxx` ID or phase name (`spec`, `architecture`, `tasks`, `implementation`). |
| **Prerequisites** | `.forge/specs/` must exist. |
| **What it does** | 1. **Phase detection** — determines the current phase from existing artifacts.<br>2. **Phase-specific validation**:<br>   - **Spec**: Checks frontmatter, description clarity, testable acceptance criteria, no implementation leaks, explicit assumptions, out-of-scope items.<br>   - **Architecture**: Checks pattern adherence, ADR rationale, schema compatibility, REST conventions, layering compliance.<br>   - **Tasks**: Checks valid frontmatter, DAG structure (no cycles), AC coverage, file listings, scoping, cross-repo `repo:` fields.<br>   - **Implementation**: Checks ACs met, tests pass, convention compliance, no lint errors, artifact statuses updated.<br>3. **Severity classification** — Blocker (must fix), Warning (should fix), Info (suggestions).<br>4. **Cross-repo validation** — in cross-repo mode, verifies every task has a valid `repo:` field matching `config.yml`. |
| **Outputs** | Pass/fail checklist with categorized issues and recommended next action. |
| **Next step** | Depends on phase: Spec → `#architect`, Architecture → implement, Tasks → implement, Implementation → `#review`. |

---

## Testing

### `#tdd`

> Generate a comprehensive failing test suite before implementation (Red-Green-Refactor).

| | |
|---|---|
| **When to call** | After `#architect` has produced tasks and before implementation begins. Part of Phase 3.5 in `#proceed`. |
| **Input** | `REQ-xxx` ID. |
| **Prerequisites** | Requirement spec and task files must exist. Existing test infrastructure (JUnit/Mockito, Jest/Vitest, etc.) must be in place. |
| **What it does** | 1. **Reads context** — requirement spec, architecture, and tasks.<br>2. **Identifies test scenarios** — extracts all acceptance criteria and edge cases.<br>3. **Writes failing tests** (Red Phase) — creates test files that compile/parse correctly but fail because business logic is not implemented yet.<br>4. **Verifies failure** — runs the test suite to prove tests execute and correctly assert the absent behavior.<br>5. **Reports** — summarizes the test suite and lists all currently-failing tests, proving spec coverage. |
| **Outputs** | Test files in appropriate directories. All tests must fail (Red phase). |
| **Next step** | Implementation phase — write code to make tests pass (Green phase). |

---

## Orchestration

### `#proceed`

> Autonomous end-to-end pipeline: validate spec → architect → TDD → implement → reflect → review → PR → wrapup.

| | |
|---|---|
| **When to call** | When you want to take a requirement from spec to shipped PR in a single automated session. Best for well-defined, self-contained features. |
| **Input** | `REQ-xxx` ID (e.g., `#proceed REQ-023`). |
| **Prerequisites** | `.forge/` initialized, requirement spec exists at `.forge/specs/REQ-xxx-*/requirement.md`. |
| **What it does** | Runs 9 phases sequentially with state tracking via `pipeline-state.json`:<br><br>**Phase 0** — Preflight: verify prerequisites, create git worktree, load shared context.<br>**Phase 1** — Validate spec (up to 3 auto-fix loops).<br>**Phase 2** — Architect: design architecture, create task files.<br>**Phase 3** — Validate architecture and tasks.<br>**Phase 3.5** — TDD: generate failing test suite.<br>**Phase 4** — Implement: execute tasks one-by-one in dependency order, commit each.<br>**Phase 5** — Verify: run reflector + 5 review dimensions (correctness, quality, architecture, tests, security), fix findings.<br>**Phase 6** — Create PR(s) via `gh pr create`.<br>**Phase 7** — PR cleanup, CI checks.<br>**Phase 7.5** — Canary deploy (if `deployable: true`).<br>**Phase 8** — Wrapup: merge, capture knowledge, emit ship summary.<br><br>**Autonomous halts** (only 5 legitimate pause points): validation fails 3×, reflector surfaces user questions, canary fails, merge conflicts, CI timeout. |
| **Outputs** | Merged PR, knowledge artifacts (lessons, ADRs, assumptions, support docs), ship summary. |
| **Resumability** | Reads `pipeline-state.json` on start — resumes from last completed phase. |

---

### `#sprint`

> Run multiple `#proceed` pipelines for a batch of REQs — sequential execution with progress dashboard.

| | |
|---|---|
| **When to call** | When you have 2-5 approved REQs that need to be implemented in one session. |
| **Input** | Space-separated REQ IDs (e.g., `#sprint REQ-091 REQ-092 REQ-093`) or `all` for all approved specs. |
| **Prerequisites** | `.forge/` initialized. Each REQ must have a spec with at least one acceptance criterion. |
| **What it does** | 1. **Pre-flight** — validates eligibility for each REQ (spec exists, no blocking questions, no worktree collisions). Reports a pre-flight table and asks for confirmation.<br>2. **Sequential execution** — runs `#proceed` inline for each REQ in order. Updates a live dashboard showing state, duration, and remaining queue.<br>3. **Blocked handling** — if a REQ hits `blocked` or `failed`, asks whether to fix/skip/abort.<br>4. **Merge sequencing** — after all pipelines, verifies merges and handles cross-repo merge ordering.<br>5. **Sprint summary** — final report with completed/blocked REQs, knowledge captured, and aggregate metrics. |
| **Outputs** | Multiple merged PRs, sprint summary dashboard, aggregated knowledge artifacts. |
| **Limits** | Max 5 REQs per sprint. Runs sequentially (no parallelism in Copilot). |

---

## Review

### `#check-drift`

> Lightweight read-only convention compliance check — flags drift without auto-fixing.

| | |
|---|---|
| **When to call** | Intermittently during active development (or automatically inside `#proceed`) to catch convention violations early. |
| **Input** | File paths, branch name, or nothing (defaults to current uncommitted + staged changes). |
| **Prerequisites** | `.forge/context/rules/conventions.rules.md` must exist. |
| **What it does** | 1. **Rule load** — reads all `.rules.md` files from `.forge/context/rules/`.<br>2. **Diff scan** — identifies changed files.<br>3. **Compare** — reads full file contents and compares them against architecture, convention, security, and deployment rules.<br>4. **Classify** — groups findings into 🔴 IRON LAW, 🟡 GOLDEN PATH, and 🔵 RULE.<br>5. **Read-only** — this prompt *never* modifies code or auto-fixes anything. |
| **Outputs** | Compact drift report showing files, lines, and specific rules violated. |
| **Next step** | Fix any 🔴 IRON LAW violations before continuing development. |

---

### `#reflect`

> Post-implementation self-review — catch issues before the formal `#review` step.

| | |
|---|---|
| **When to call** | After implementing a feature, before running `#review`. Think of it as "checking your own work." |
| **Input** | `REQ-xxx` ID, branch name, or nothing (defaults to current branch vs `main`). |
| **Prerequisites** | `.forge/context/conventions.md` must exist. |
| **What it does** | 1. **Scope detection** — finds the relevant diff (`git diff main...HEAD`).<br>2. **Full file read** — reads complete current versions of all changed files (not just the diff).<br>3. **Lesson check** — searches `.forge/knowledge/lessons/` for lessons matching affected areas.<br>4. **Self-review checklist** — checks correctness (ACs met, edge cases, error paths, race conditions), convention compliance (naming, logging, config, API format), architecture (layering, DI, business logic location), testing (coverage, error paths, mocks, determinism), completeness (no TODOs, debug logs, commented-out code).<br>5. **Surfaces questions** — ambiguous requirements, design tradeoffs, assumptions, deferred edge cases.<br>6. **Fix or defer** — Critical issues fixed immediately, Major issues offered to user, Minor listed. |
| **Outputs** | Self-review findings with severity ratings. Fixes applied if critical. |
| **Next step** | `#review` for formal multi-dimension code review. |

---

### `#review`

> Multi-dimension code review covering correctness, quality, architecture, test coverage, and security.

| | |
|---|---|
| **When to call** | After implementation and `#reflect`. This is the formal quality gate before merge. |
| **Input** | File paths, branch name, REQ/TASK ID, or nothing (defaults to current branch vs `main`). |
| **Prerequisites** | `.forge/context/conventions.md` and `architecture.md` must exist. |
| **What it does** | Runs 5 review dimensions sequentially, each referencing the full agent checklist in `.github/prompts/agents/`:<br><br>**Dimension 1 — Correctness**: Logic errors, null risks, race conditions, missing async handling, injection, auth bypass, data exposure.<br>**Dimension 2 — Quality**: Naming conventions, logging patterns, hardcoded values, code duplication, input validation.<br>**Dimension 3 — Architecture**: Layering violations, business logic placement, API contract changes, backward compatibility, **documentation drift** (new env vars not in `variables.md` = Critical).<br>**Dimension 4 — Test Coverage**: Missing test files, error path coverage, mock completeness, brittle assertions, non-deterministic tests.<br>**Dimension 5 — Security**: Input validation, auth middleware, PII in logs, sensitive fields in responses, rate limiting, `npm audit`.<br><br>Consolidates findings, deduplicates, cross-references against known lessons (lesson matches escalate severity by one level). Also appends deferred Minor/Nit findings to `.forge/context/code-debt.md`. |
| **Outputs** | Dimension summary table with pass/fail gates. Ranked findings by severity. **Gate rule**: any Critical finding = overall FAIL. Deferred items appended to tech debt ledger. |
| **Next step** | Fix critical findings, then `#wrapup` or merge. |

---

## Bug Fixing

### `#bugfix`

> End-to-end bug fix workflow: report → analyze → fix → verify → ship → knowledge capture.

| | |
|---|---|
| **When to call** | When you have a bug to fix — either as a new report or referencing an existing `BUG-xxx` ID. |
| **Input** | Bug description in natural language, or `BUG-xxx` ID for an existing report. |
| **Prerequisites** | `.forge/bugs/` must exist. |
| **What it does** | 7 phases:<br><br>**Phase 1 — Report**: Creates `BUG-xxx-slug.md` using the bug template, or reads existing report. Cross-repo: adds `repo:` or `touched_repos:` to frontmatter.<br>**Phase 2 — Analyze**: Traces code paths, identifies root cause (not just symptoms), documents in the bug report.<br>**Phase 3 — Fix**: Creates `fix/bug-xxx-slug` branch, implements fix following conventions, updates tests.<br>**Phase 4 — Verify**: Runs test suite, updates bug report with resolution details.<br>**Phase 5 — Ship**: Pushes branch, creates PR via `gh pr create`, waits for CI.<br>**Phase 6 — Canary** (optional): Runs `#canary` for high/critical severity bugs touching deployable services.<br>**Phase 7 — Wrapup**: Merges PR, confirms deploys (staging + production), captures lesson, cleans up branches/worktrees, emits ship summary. |
| **Outputs** | Merged fix PR, updated bug report (`status: resolved`), lesson captured (if applicable), ship summary. |
| **Knowledge** | Always evaluates whether the bug revealed a lesson. If yes, writes `LESSON-xxx-slug.md`. |

---

## Lightweight Workflows

### `#vibe`

> Fast, lightweight "Vibe Coding" workflow for trivial changes — no heavy specs, no new tests.

| | |
|---|---|
| **When to call** | For small, isolated changes that don't need the full SDD pipeline. `#spec` will automatically suggest `#vibe` when appropriate. Good for: cosmetic fixes, config tweaks, copy changes, single-file edits. |
| **Input** | Requirement description in natural language. |
| **Prerequisites** | `.forge/` must exist. |
| **What it does** | 4 phases:<br><br>**Phase 1 — Implement**: Locates relevant files, makes minimal differential edits. No new unit tests written.<br>**Phase 2 — Verify**: Runs the existing test suite to ensure nothing broke.<br>**Phase 3 — Traceability**: Creates `VIBE-xxx-slug.md` in `.forge/specs/vibe/` as a lightweight as-built doc (intent, files modified, verification results).<br>**Phase 4 — Commit**: Immediately commits with `feat(VIBE-xxx): <description>`. |
| **Outputs** | Committed change + traceability doc. No PR, no full review. |
| **When NOT to use** | Cross-boundary changes, DB/schema changes, security/auth changes, new infrastructure, anything needing tests. |

---

## Knowledge Capture

### `#query`

> Query project knowledge, answer using `.forge` context, and optionally capture or enhance knowledge in `.forge/knowledge/`.

| | |
|---|---|
| **When to call** | Anytime you want to ask a question, discuss a design, or capture new knowledge that isn't tied to an active pipeline. |
| **Input** | A question, design discussion, historical context request, or free text that may represent knowledge worth saving. |
| **Prerequisites** | `.forge/knowledge/` must exist (run `#init` if not). |
| **What it does** | 1. **Intent Detection** — determines if you are querying, capturing, or doing a hybrid of both.<br>2. **Context Retrieval** — searches `.forge/context/` and `.forge/knowledge/` to ground its answers.<br>3. **Discussion** — answers questions and acts as a senior engineer grounded in project history.<br>4. **Action Proposal** — if durable knowledge is created, proposes creating, enhancing, or merging knowledge docs.<br>5. **Structure & Tag** — if approved, formats knowledge into templates and tags with taxonomy.<br>6. **Write** — saves to `.forge/knowledge/<type>/` and updates `_index.md`. |
| **Outputs** | Conversational answers, and optionally updated knowledge documents in `.forge/knowledge/`. |

#### Knowledge Types at a Glance

| Type | Template | Directory | Use When |
|------|----------|-----------|----------|
| **lesson** | `lesson-template.md` | `knowledge/lessons/` | A takeaway from experience — do this / avoid that |
| **assumption** | `assumption-template.md` | `knowledge/assumptions/` | A belief to track — validated, invalidated, or unresolved |
| **adr** | `adr-template.md` | `knowledge/decisions/` | An architectural or technical decision with rationale |
| **support** | `support-template.md` | `knowledge/support/` | User-facing docs, FAQs, troubleshooting guides |
| **qa** | `manual-qa-template.md` | `knowledge/qa/` | Manual test guides with step-by-step verification |

---

### `#synthesize`

> Process raw learning candidates from `.forge/knowledge/inbox/` into permanent project knowledge.

| | |
|---|---|
| **When to call** | Periodically — after a few `#reflect`, `#review`, or `#wrapup` sessions have deposited candidates into the inbox. |
| **Input** | None — processes all files in `.forge/knowledge/inbox/`. |
| **Prerequisites** | `.forge/knowledge/inbox/` must exist (scaffolded by `#init`). At least one candidate file must be present. |
| **What it does** | 1. **Scans inbox** — lists all candidate files in `.forge/knowledge/inbox/`.<br>2. **Classifies each candidate** — lesson, convention update, ADR, or reject.<br>3. **Routes and applies**:<br>   - **Lesson**: Formats using `lesson-template.md`, saves to `.forge/knowledge/lessons/`.<br>   - **Convention update**: Proposes a diff to the relevant `.rules.md` file and waits for user approval before applying.<br>   - **ADR**: Formats using `adr-template.md`, saves to `.forge/knowledge/decisions/`.<br>   - **Reject**: Moves to `.forge/knowledge/archive/` with a reason.<br>4. **Summary report** — counts of lessons created, ADRs created, rules updated, and candidates archived. |
| **Outputs** | Permanent knowledge artifacts (lessons, ADRs, rule updates). Archived rejects. Summary report. |

---

### `#prune`

> Periodic knowledge hygiene — verify rules and lessons against the codebase and archive stale items.

| | |
|---|---|
| **When to call** | Periodically (e.g., monthly or after major refactors) to keep `.forge/` knowledge lean and accurate. |
| **Input** | None — audits all rules and lessons. |
| **Prerequisites** | `.forge/context/rules/` and `.forge/knowledge/lessons/` must exist. |
| **What it does** | 1. **Gathers knowledge** — reads all `.rules.md` files and lesson files.<br>2. **Empirical verification** — searches the codebase to check if each rule/lesson still reflects reality.<br>3. **Classifies** each item as `active`, `stale-factual`, `stale-aspirational`, or `superseded`.<br>4. **Proposes pruning** — presents the archival list to the user for approval before making changes.<br>5. **Archives** approved items to `.forge/knowledge/archive/` with reasoning.<br>6. **Hygiene report** — lists pruned, borderline (widely violated but still important), and healthy items. |
| **Outputs** | Hygiene report. Archived stale knowledge (with user approval). |

---

## Completion

### `#wrapup`

> Close out a completed feature — commit, merge, deploy, capture knowledge, emit ship summary.

| | |
|---|---|
| **When to call** | After a feature has been implemented and reviewed. This is the final step before moving on. Usually invoked automatically at the end of `#proceed`. |
| **Input** | `REQ-xxx` ID (or inferred from current branch / recent merges). |
| **Prerequisites** | Feature implementation complete, ideally reviewed via `#review`. |
| **What it does** | 7 steps:<br><br>**Step 1 — Identify**: Locates all artifacts for the REQ. Detects single vs cross-repo mode.<br>**Step 2 — Commit, Push, Merge**: Branch check (never on `main`), pre-commit security scan, `git add/commit/push`, create PR if none exists, rebase if behind main, merge via `gh pr merge --squash`.<br>**Step 3 — Update statuses**: Sets requirement and all tasks to `status: complete`.<br>**Step 4 — Capture knowledge**: Architectural decisions (local in architecture.md or global ADRs), assumptions (validated/invalidated/unresolved), lessons learned, convention updates, support documentation, manual QA guide.<br>**Step 5 — Ship summary**: Generates formatted summary with status, branch, PR, what shipped, key decisions, metrics (files, lines, tests, tokens), deferred items, follow-ups.<br>**Step 5b — Token estimate**: Runs `.\scripts\token-estimate.ps1` for session cost metrics.<br>**Step 6 — Deploy**: Walks touched repos and deploys (Cloud Run, AKS, iOS, IaC).<br>**Step 7 — Recommend next steps**: Suggests specs for deferred items, monitoring, convention review. |
| **Outputs** | Merged PR(s), knowledge artifacts, ship summary, deployment confirmation. |

---

## Deployment

### `#canary`

> Canary deployment — deploy a zero-traffic revision, run smoke tests, promote on success.

| | |
|---|---|
| **When to call** | Before promoting a new version to production. Used automatically in `#proceed` Phase 7.5 for deployable requirements, and in `#bugfix` Phase 6 for high-severity bugs. Can also be invoked standalone. |
| **Input** | Repo ID from `.forge/config.yml`, Cloud Run service name, or nothing for auto-detection. |
| **Prerequisites** | `gcloud` CLI authenticated, Docker image available, Cloud Run service exists. |
| **What it does** | 1. **Service resolution** — resolves the target service from `config.yml`, argument, or auto-detection.<br>2. **Build & push** — builds Docker image tagged `canary-<SHA>` and pushes to registry.<br>3. **Zero-traffic deploy** — deploys canary revision with `--no-traffic --tag=canary`.<br>4. **Health checks** — retries up to 3× with 5s intervals (cold start grace period).<br>5. **Smoke tests** — reads custom tests from `.forge/context/smoke-tests.md` or uses defaults. Reports pass/fail table.<br>6. **Promote** — on all-pass, migrates 100% traffic to canary revision, cleans up tag.<br>7. **Rollback** — on any failure, removes canary tag, leaves production traffic unchanged. Suggests log reading command. |
| **Outputs** | Smoke test results table. Either "Canary promoted to production" or "CANARY FAILED — rolled back." |

---

### `#deploy`

> Execute deployment steps based on the project's deployment configuration.

| | |
|---|---|
| **When to call** | When you want to deploy or run the project locally, to staging, or to production. |
| **Input** | Deployment target: `local` (default), `staging`, or `production`. |
| **Prerequisites** | `.forge/context/deployment.md` must exist (created by `#init`). |
| **What it does** | 1. **Target resolution** — determines local/staging/production from user input.<br>2. **Secret verification** — checks required secrets in `.forge/.env.local`. Stops if any are missing.<br>3. **Execution** — runs the deployment steps defined in `.forge/context/deployment.md` sequentially.<br>4. **Verification** — pings health endpoints or checks local ports to confirm deployment. |
| **Outputs** | Deployed application with accessible URL/endpoint confirmation. |

---

## Integration

### `#issue_epic_creation`

> Synchronize local REQs and Tasks to GitLab as Epics and Issues.

| | |
|---|---|
| **When to call** | After `#architect` has produced tasks and before starting implementation, if your team uses GitLab for issue tracking. |
| **Input** | `REQ-xxx` ID to sync. |
| **Prerequisites** | `.forge/.env.local` must have `GITLAB_TOKEN`, `GITLAB_URL`, `GITLAB_GROUP_ID`, and project IDs configured. |
| **What it does** | 1. **Reads local specs** — reads the requirement and all task files for the given REQ.<br>2. **Creates Epic** — creates a GitLab Epic at the Group level using the GitLab REST API, capturing the Epic IID for linking.<br>3. **Creates Issues** — for each task, determines the target GitLab project and creates an Issue linked to the Epic.<br>4. **Verification** — prints a success summary with hyperlinks to the newly created Epic and Issues. |
| **Outputs** | GitLab Epic + linked Issues. |

---

## Visibility & Health

### `#status`

> Show current state of all Copilot Forge work across the project.

| | |
|---|---|
| **When to call** | Anytime you want a quick overview of project progress — what's in flight, what's blocked, what's recently completed. |
| **Input** | Optional filter: `REQ-xxx` (specific REQ), `in-progress`, `bugs`, or nothing for full dashboard. |
| **Prerequisites** | `.forge/specs/` must exist. |
| **What it does** | 1. **Scans all artifacts** — reads all requirement specs, tasks, bug reports, and `pipeline-state.json` files.<br>2. **Builds dashboard** — Requirements summary table (REQ, title, status, task progress), active pipelines (current phase, started, touched repos), cross-repo activity, in-progress work, open bugs, recently completed (last 7 days).<br>3. **Filters** — applies any user-specified filter.<br>4. **Action items** — lists recommended next actions: draft specs needing validation, approved specs needing architecture, tasks ready to implement, open bugs. |
| **Outputs** | Status dashboard with tables and recommended actions. |

---

### `#analyze`

> Codebase health audit — identify technical debt, quality issues, and improvement opportunities.

| | |
|---|---|
| **When to call** | Periodically to check codebase health. Also useful after manual code changes or `git pull` to sync `.forge/context/` docs with reality (drift resolution). |
| **Input** | Optional: specific directory, focus area (`security`, `testing`, `performance`), or nothing for full audit. |
| **Prerequisites** | `.forge/context/architecture.md` and `conventions.md` must exist. |
| **What it does** | 1. **Incremental analysis** — reads `.forge/.last-analyzed-commit` to identify only changed files since last run. Updates context docs to resolve drift. Saves new commit hash after completion.<br>2. **4 audit dimensions** (run sequentially, referencing agent checklists):<br>   - **Code Quality**: Dead code, duplication, complexity, inconsistent patterns, maintenance markers.<br>   - **Convention Compliance**: Naming, logging, config, API format, error handling, import style violations.<br>   - **Security**: Input validation, auth middleware, PII in logs, sensitive fields, rate limiting, `npm audit`.<br>   - **Testing**: Coverage gaps, error path testing, mock completeness, brittle assertions, determinism.<br>3. **Repo hygiene** — stale branches, merged branches, TODO/FIXME counts.<br>4. **Health scorecard** — A–F grade per dimension + overall. Critical issues, tech debt, improvement opportunities.<br>5. **Persist State** — Overwrites `.forge/context/quality-radar.md`, appends to `.forge/context/code-debt.md`, and updates tool versions in `.forge/context/codebase-state.md`.<br>6. **Recommendations** — top 5 ranked by impact/effort, with suggestions for `#spec` candidates. |
| **Outputs** | Health scorecard (saved to `quality-radar.md`), tech debt logged to `code-debt.md`, categorized findings, prioritized recommendations. |

---

### `#optimize`

> API cost & performance scanner — identify expensive operations and optimization opportunities.

| | |
|---|---|
| **When to call** | When you want to find performance bottlenecks, reduce API costs, or optimize database queries. |
| **Input** | Optional focus area: `ai`, `caching`, `queries`, `latency`, or nothing for all dimensions. |
| **Prerequisites** | `.forge/context/architecture.md` must exist. |
| **What it does** | 3 scanner dimensions (referencing agent checklists):<br><br>**Dimension 1 — API Cost Analysis**: AI API call inventory (model, tokens, frequency), model selection optimization, caching strategy (system prompt caching, L1/L2), redundant calls, cost estimates.<br>**Dimension 2 — Database Performance**: Query issues (missing indexes, N+1, unbounded queries), connection pool, pagination, atomic operations, batch operations, cache effectiveness (`@Cacheable`/`@CacheEvict`).<br>**Dimension 3 — Latency Analysis**: Sequential blocking calls, response payload sizes, controller/filter overhead, thread pool sizing, throughput issues.<br><br>Produces cost summary, performance hotspot ranking, and prioritized optimization opportunities with impact/effort/risk ratings. |
| **Outputs** | Cost summary table, performance hotspots, optimization recommendations ranked by ROI. |

---

## Security

### `#security_scan`

> Interactive pre-commit secret and credential audit.

| | |
|---|---|
| **When to call** | Before committing sensitive code changes, or anytime you want to verify no secrets are in the diff. Runs automatically as part of `#wrapup` Step 2. |
| **Input** | None — scans the current uncommitted diff. |
| **Prerequisites** | Git repository with uncommitted changes. |
| **What it does** | 1. **Scans diff** — runs `git diff` and `git diff --cached` to gather all pending changes.<br>2. **Pattern matching** — scans for PATs (`glpat-`, `ghp_`, `xoxb-`), API keys (`AIZA...`, `sk-...`), private keys, hardcoded passwords, connection strings, credentials in `.env` files.<br>3. **Interactive audit** — for each finding, presents file, line, snippet, and risk level. Asks user to confirm: **Remove** (must fix) or **False Positive** (safe to commit).<br>4. **Gate** — does NOT give "Security Clear" until every finding is addressed. |
| **Outputs** | Audit report. No "clear" status until all findings resolved. |

---

## Maintenance

### `#forge-admin`

> Admin control plane for Copilot Forge maintenance — audit, patch, standardize, and govern prompt/instruction/agent updates.

| | |
|---|---|
| **When to call** | When you want to add, rename, modify, or deprecate prompts, agents, templates, or pipeline scripts within the Forge toolkit. |
| **Input** | Action (`audit`\|`patch`\|`standardize`\|`deprecate`\|`index`), Target, `REQ-xxx` ID, and Change intent. |
| **Prerequisites** | Must be executed in a repository with the Forge toolkit installed. |
| **What it does** | 1. **Dependency Graph Scan** — flags downstream breakage before a change is applied.<br>2. **Guided Modification** — maps the change to affected files and executes it via a lightweight REQ spec.<br>3. **Scaffold Generation** — scaffolds correctly structured files with proper frontmatter.<br>4. **Post-Modification Validation** — runs a consistency sweep to verify all cross-references resolve. |
| **Outputs** | Commits to `.github/prompts`, `templates`, or `scripts`, tracked by a REQ spec. |

---

### `#template-drift`

> Detect drift between a project's local `.forge/templates/` and the canonical toolkit templates.

| | |
|---|---|
| **When to call** | After pulling toolkit updates, or periodically to check template freshness. |
| **Input** | Optional: specific template name (e.g., `requirement-template`), or nothing to check all. |
| **Prerequisites** | `.forge/templates/` must exist in the project. |
| **What it does** | 1. **Enumerate** — lists all templates in both `.forge/templates/` (local) and `templates/` (canonical). Catches templates added upstream but missing locally, and vice versa.<br>2. **Diff** — reads and compares both versions of each template. Captures line-level differences.<br>3. **Classify drift** — distinguishes **intentional customization** (project-specific sections, editorial choices) from **accidental staleness** (upstream added features, cosmetic differences).<br>4. **Drift report** — table showing each template's status (Identical/Drifted/Missing), drift size (+/- lines), and classification.<br>5. **Reconciliation** — offers specific actions for accidental drift and missing templates. **Never applies changes without explicit user approval**. |
| **Outputs** | Drift report with classification. User-approved reconciliation actions. |

---

## Metrics

### `#token-estimate`

> Estimate token consumption per pipeline phase for a REQ session.

| | |
|---|---|
| **When to call** | Before or after a `#proceed` run to understand token costs. For routine use, prefer running `.\scripts\token-estimate.ps1` directly from the terminal (zero Copilot token cost). |
| **Input** | `REQ-xxx` ID (optional — estimates baseline context only if omitted). |
| **Prerequisites** | `.forge/` must be initialized. |
| **What it does** | 1. **Measures** baseline context files, REQ-specific artifacts, prompt files per phase, agent checklists, and knowledge retrieval files.<br>2. **Formula**: `estimated_tokens = ceil(file_size_in_bytes / 4)` (~4 chars/token for English/Markdown).<br>3. **Phase breakdown** — calculates tokens for each of the 9 pipeline phases based on what files are loaded.<br>4. **Output estimation** — applies ~25% multiplier for estimated output tokens.<br>5. **Writes results** to `pipeline-state.json` under `tokenEstimate`.<br>6. **Reports** — phase-by-phase table with token counts, percentages, and largest-phase callout. |
| **Outputs** | Token estimate table, `pipeline-state.json` update. Accuracy: ±15–20%. |
| **Alternative** | Run `.\scripts\token-estimate.ps1` from the terminal for the same estimate without consuming Copilot tokens. |

---

## Agent Reference Checklists

These live in `.github/prompts/agents/` and are **not invoked directly** by users. They are referenced inline by the prompts listed below.

| Agent Checklist | Used By | Focus |
|-----------------|---------|-------|
| `reflector` | `#reflect`, `#proceed` Phase 5 | Self-review: correctness, conventions, completeness |
| `correctness-reviewer` | `#review`, `#proceed` Phase 5 | Logic errors, null risks, race conditions, security |
| `quality-reviewer` | `#review`, `#proceed` Phase 5 | Naming, conventions, duplication, validation |
| `architecture-reviewer` | `#review`, `#proceed` Phase 5 | Layering, separation of concerns, API contracts |
| `test-auditor` | `#review`, `#analyze`, `#proceed` Phase 5 | Coverage gaps, mock completeness, test quality |
| `security-auditor` | `#review`, `#analyze`, `#proceed` Phase 5 | Injection, auth, data exposure, rate limiting |
| `feature-tracer` | `#architect` | Traces similar existing implementations |
| `architecture-mapper` | `#architect` | Maps affected files and dependency layers |
| `integration-explorer` | `#architect` | Identifies extension points and API contracts |
| `convention-auditor` | `#analyze` | Convention compliance checking |
| `code-quality-auditor` | `#analyze` | Dead code, duplication, complexity |
| `api-cost-scanner` | `#optimize` | AI API call inventory and cost estimation |
| `db-perf-scanner` | `#optimize` | Database query performance analysis |
| `latency-scanner` | `#optimize` | Request path latency analysis |
| `task-implementer` | `#proceed` Phase 4 | Task implementation guidelines |

---

## Decision Flowchart: Which Prompt Should I Use?

```
Start
  │
  ├─ New project, no .forge/ yet?
  │    └─ #init
  │
  ├─ Have a feature to build?
  │    ├─ Small, isolated, no tests needed?
  │    │    └─ #vibe
  │    ├─ Want full automation?
  │    │    └─ #proceed REQ-xxx  (or #sprint for batch)
  │    └─ Want step-by-step control?
  │         └─ #spec → #validate → #architect → #validate → #tdd → implement → #reflect → #review → #wrapup
  │
  ├─ Have a bug to fix?
  │    └─ #bugfix
  │
  ├─ Want to capture something you learned?
  │    └─ #query
  │
  ├─ Have learning candidates in the inbox?
  │    └─ #synthesize
  │
  ├─ Want to clean up stale knowledge?
  │    └─ #prune
  │
  ├─ Want to check project health?
  │    ├─ Code quality & tech debt → #analyze
  │    ├─ Performance & costs → #optimize
  │    ├─ Secrets in code → #security_scan
  │    └─ Template freshness → #template-drift
  │
  ├─ Are you mid-implementation and want a quick convention check?
  │    └─ #check-drift
  │
  ├─ Want to modify the Forge toolkit?
  │    └─ #forge-admin
  │
  ├─ Want visibility?
  │    ├─ What's in progress → #status
  │    └─ Token costs → #token-estimate
  │
  ├─ Need to deploy?
  │    ├─ Standard deploy → #deploy
  │    └─ Canary (zero-traffic first) → #canary
  │
  └─ Need to sync to GitLab?
       └─ #issue_epic_creation
```
