---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Multi-dimension code review covering correctness, quality, architecture, test coverage, and security
---

# review — Multi-Dimension Code Review

You are performing a thorough code review of recent changes covering 5 dimensions: correctness, quality, architecture, test coverage, and security.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
>

## Input

Scope: [file paths, branch name, REQ/TASK ID, or nothing for current branch — provided by the user]

## Prerequisites

Use the codebase tool to verify `.forge/context/conventions.md` exists. If it doesn't, stop and tell the user: "The `.forge/` structure hasn't been initialized. Run `#init` first."

## Instructions

### Step 1: Determine Review Scope and Load Context
1. If given specific file paths, review those files.
2. If given a branch name, review all changes on that branch vs `main`.
3. If given a REQ/TASK ID, find the associated branch and review its changes.
4. If no argument, review all changes on the current branch vs `main`.
5. Run in terminal: `git diff main...HEAD` (or `git diff` for uncommitted changes).
6. Read `.forge/context/conventions.md` via the codebase tool.
7. Read `.forge/context/architecture.md` via the codebase tool.
8. **Relevant lessons**: derive touched components from the diff file paths. Search `.forge/knowledge/lessons/` for lessons where `component` or `domain` matches touched areas. Read matched lessons and pass them to each review dimension.

### Step 2: Read All Changed Files
Read the complete current version of every changed file (not just the diff) to understand full context.

### Step 3: Run Review Dimensions Sequentially

Run each review dimension in order. For each, produce structured findings with severity (Critical/Major/Minor/Nit), file path, line number, and suggested fix.

#### Dimension 1 — Correctness (reference: `#agents/correctness-reviewer`)
Focus: logic errors, null risks, race conditions, edge cases, concurrency bugs.
- Off-by-one errors in loops and array indexing
- Incorrect boolean logic (inverted conditions, missing negations)
- Incorrect null/undefined handling (missing guards)
- Missing await on async functions; unhandled promise rejections
- Missing try/catch around operations that can throw; swallowed errors
- SQL/NoSQL injection via unsanitized user input
- Authentication bypass (missing auth checks on endpoints)
- Data exposure (PII in logs, sensitive fields in API responses)
- Empty inputs, boundary values, concurrent modification scenarios

#### Dimension 2 — Quality (reference: `#agents/quality-reviewer`)
Focus: naming, convention compliance, code duplication, complexity.
- Naming conventions per `.forge/context/conventions.md`
- Logging — uses project logger, not `console.log`
- No hardcoded values (URLs, ports, timeouts) — must use config
- No copy-pasted logic that should be extracted to a shared function
- User input validated at API boundaries
- Import/export style per conventions

#### Dimension 3 — Architecture (reference: `#agents/architecture-reviewer`)
Focus: layering, separation of concerns, API contracts, backward compatibility.
- Routes contain only request parsing and response formatting
- Business logic lives in services, not route handlers
- Data access encapsulated in repositories only
- Each layer only calls the layer directly below it
- Breaking changes to existing endpoints are flagged
- Database schema changes are additive

#### Dimension 4 — Test Coverage (reference: `#agents/test-auditor`)
Focus: test coverage gaps, mock completeness, test quality, determinism.
- New code has corresponding test files (scan both centralized and colocated test layouts before reporting a gap)
- Tests cover error/failure paths, not just happy path
- Mock files include all new exports
- No brittle assertions; no tests that depend on system clock
- No tests that make real network calls
- For any "no test file" finding, run in terminal: `find . -name '<filename>.test.*' -o -name '<filename>.spec.*' | grep -v node_modules` to verify before reporting

#### Dimension 5 — Security (reference: `#agents/security-auditor`)
Focus: input validation, auth/authz, data exposure, rate limiting, dependency issues.
- User input validated and sanitized at API boundaries
- Authentication middleware present on protected endpoints
- Authorization checks present (resource ownership verification)
- PII not in log messages
- Sensitive fields not returned in API responses
- Rate limiting on expensive or auth endpoints
- Run in terminal: `npm audit` (if package.json exists) and report findings

### Step 4: Consolidate Findings
1. Deduplicate overlapping findings across dimensions.
2. Categorize by severity:
   - **Critical**: Must fix before merge (bugs, security, data loss)
   - **Major**: Should fix before merge (convention violations, missing tests)
   - **Minor**: Nice to fix (style, naming)
   - **Nit**: Optional suggestions
3. Cross-reference findings against the loaded lessons — if a finding matches a known pitfall, escalate its severity by one level and flag it explicitly.

### Step 5: Present Review

Display a dimension summary first:

```
## Dimension Summary

| Dimension    | Critical | Major | Minor | Nit | Gate |
|---|---|---|---|---|---|
| Correctness  | 0 | 0 | 0 | 0 | PASS |
| Quality      | 0 | 0 | 0 | 0 | PASS |
| Architecture | 0 | 0 | 0 | 0 | PASS |
| Test Coverage| 0 | 0 | 0 | 0 | PASS |
| Security     | 0 | 0 | 0 | 0 | PASS |

**Overall gate: PASS / FAIL**
```

Then list findings organized by file, then by severity within each file.

**Gate rule**: if ANY dimension reports a `Critical` finding, the overall gate FAILS. Fix critical findings before pushing.

### Step 6: Summary
1. Overall gate: PASS / FAIL / RESHAPE
2. Count of issues by severity and by dimension
3. Top 3 most important things to address
4. Any findings that matched recent lessons (elevated-severity items)
5. If changes look good, say so clearly — an empty review is a valid result for small, well-scoped changes
