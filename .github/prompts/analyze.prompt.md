---
agent: agent
tools: [codebase, runCommand, terminalLastCommand]
description: Codebase health audit — identify technical debt, quality issues, and improvement opportunities
---

# analyze — Codebase Health Audit

You are performing a comprehensive codebase health audit for the current project.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
>
> **Copilot difference**: The original `/analyze` skill dispatched 4 audit agents in parallel. In Copilot, run all 4 audit dimensions sequentially. Reference the agent checklist prompts in `.github/prompts/agents/` for the full per-dimension checklists.

## Input

Scope: [specific directory, focus area ("security", "testing", "performance"), or nothing for full audit]

## Instructions

### Step 1: Determine Scope
1. If given a specific directory or area, focus the audit there.
2. If given a focus area, prioritize that dimension.
3. If no argument, perform an incremental audit (see Step 1.5).
4. Read `.forge/context/rules/architecture.rules.md` and `.forge/context/rules/conventions.rules.md` via the codebase tool.

### Step 1.5: Incremental Analysis (Drift Sync)
To prevent hallucination and maintain sync after manual edits or `git pull` events, Copilot Forge tracks what it has already analyzed.
1. Check if `.forge/.last-analyzed-commit` exists using the terminal.
2. If it exists, read the stored git hash. Run `git diff --name-only <stored-hash> HEAD` and `git status -s` to get a precise list of files changed, added, or untracked since the last analysis.
3. Focus your codebase search and audit **only** on those changed files. If those new files diverge from the existing `.forge/context/` documentation, automatically update the documentation to reflect the new reality (this resolves drift).
4. If the file doesn't exist, audit the entire project.
5. **CRITICAL**: Once the analysis is complete, run `git rev-parse HEAD > .forge/.last-analyzed-commit` to save the state for the next run.

### Step 2: Run Audit Dimensions Sequentially

#### Dimension 1 — Code Quality (reference: `#agents/code-quality-auditor`)
Check for:
- **Dead code**: unused exports, unreachable branches, commented-out code blocks, deprecated functions
- **Code duplication**: copy-pasted logic, near-duplicate functions, repeated patterns without abstraction
- **Complexity**: high cyclomatic complexity, deeply nested conditionals (3+ levels), functions >50 lines, files >300 lines
- **Inconsistent patterns**: same operation done multiple ways, mixed paradigms
- **Maintenance markers**: TODOs, FIXMEs, HACKs, workarounds with no ticket

#### Dimension 2 — Convention Compliance (reference: `#agents/convention-auditor`)
Read `.forge/context/rules/conventions.rules.md` first — it is the source of truth.
- Naming violations (files, types, variables, functions, route paths, constants)
- Logging violations — direct `console.log`/`print` usage instead of project logger
- Configuration violations — hardcoded URLs, ports, timeouts, magic numbers
- API response format violations
- Error handling pattern violations (empty catch blocks, swallowed errors)
- Import/export style violations

Use the codebase tool to grep for common patterns:
- `console.log` / `console.warn` in `.js`/`.ts` files
- `require(` in ESM projects
- Hardcoded URLs (search for `http://` or `https://` in source files)

#### Dimension 3 — Security (reference: `#agents/security-auditor`)
- User input not validated or sanitized at API boundaries
- Endpoints missing authentication middleware
- PII in log messages
- Sensitive fields returned in API responses (passwords, tokens)
- Rate limiting missing on expensive or auth endpoints
- Run in terminal: `npm audit` (if package.json exists)

#### Dimension 4 — Testing (reference: `#agents/test-auditor`)
- Source files with no corresponding test file (check both centralized and colocated layouts before reporting a gap)
- Functions with no test coverage
- Error paths not tested
- API routes without integration tests
- Mock files missing exports from mocked modules
- Brittle assertions, non-deterministic tests
- Run in terminal: `npm test -- --coverage` (if applicable) to get coverage data

### Step 2a: Repo Hygiene Checks
Run these terminal checks directly:

**Stale branches (local, no commits in 90+ days)**:
```bash
git for-each-ref --sort=committerdate refs/heads/ \
  --format='%(committerdate:short) %(refname:short)' \
  | awk -v c="$(date -d '90 days ago' +%Y-%m-%d 2>/dev/null || date -v-90d +%Y-%m-%d)" '$1 < c'
```

**Branches already merged into main**:
```bash
git branch --merged main | grep -vE "^\*|main|master"
```

**TODO/FIXME count**:
```bash
grep -r "TODO\|FIXME\|HACK\|XXX" --include="*.js" --include="*.ts" --include="*.swift" . | grep -v node_modules | wc -l
```

### Step 3: Consolidate Results

#### Health Scorecard
| Dimension | Score | Summary |
|-----------|-------|---------|
| Code Quality | A-F | Key findings |
| Convention Compliance | A-F | Key findings |
| Security | A-F | Key findings |
| Testing | A-F | Key findings |
| Repo Hygiene | A-F | Stale branches, TODOs |
| **Overall** | **A-F** | |

#### Critical Issues (fix now)
Issues posing immediate risk — security vulnerabilities, data loss potential, broken functionality.

#### Technical Debt (fix soon)
Issues that slow development over time — duplicated code, missing tests, convention drift.

#### Improvement Opportunities (fix later)
Nice-to-have improvements — refactoring opportunities, performance optimizations.

### Step 4: Recommendations
1. Rank the top 5 most impactful improvements.
2. For each, estimate effort (small/medium/large) and impact (low/medium/high).
3. Suggest which items could become Copilot Forge requirements (candidates for `#spec`).

## Internal Reference
- **Incoming Skill Dependencies**: *None*
- **Incoming Agent Dependencies**: *None*
- **Outgoing Skill Dependencies**: *None*
- **Outgoing Agent Dependencies**: `#agents/code-quality-auditor`, `#agents/convention-auditor`, `#agents/security-auditor`, `#agents/test-auditor`
- **Resource Dependencies**: *None*
