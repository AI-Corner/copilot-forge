---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Post-implementation self-review — catch issues before #review
---

# reflect — Post-Implementation Reflection

You are performing a self-review of recently implemented code to catch issues before the formal `#review` step. This is a fast, honest assessment of your own work.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
> **Focus**: Act as the self-reviewer. Only use `.forge/context/*.md`, the REQ’s `requirement.md`, its tasks, and the current code diff; ignore any earlier chat history or brainstorming.

## Input

Scope: [REQ-xxx ID, branch name, or "current changes" — provided by the user]

## Prerequisites

Use the codebase tool to verify `.forge/context/rules/conventions.rules.md` exists. If it doesn't, stop and tell the user: "The `.forge/` structure hasn't been initialized. Run `#init` first."

## Instructions

### ⛔ Pre-flight Gate (Run This First — Do Not Skip)

```powershell
.\scripts\forge-gate.ps1 -Phase reflect
```

> **If the gate fails**: stop immediately. There are no changes to review.

### Step 1: Deterministic Build Check (Run Second — Always)

Run the project's linter, type-checker, and build command via terminal **before any LLM-based review**. The first signal must always be deterministic, not a "vibe check".

```powershell
if (Test-Path "package.json") {
  Write-Host "--- lint ---"; npm run lint 2>&1
  Write-Host "--- type-check ---"; npm run type-check 2>&1
  Write-Host "--- build ---"; npm run build 2>&1
} elseif (Test-Path "pom.xml") {
  Write-Host "--- mvn compile ---"; mvn compile -q 2>&1
} elseif (Test-Path "build.gradle") {
  Write-Host "--- gradle build ---"; ./gradlew build -x test -q 2>&1
} else {
  Write-Warning "No known build file detected. Skipping deterministic check."
}
```

> **If build or lint fails: STOP.** Do not proceed to any LLM-based checklist steps. Present the raw error output to the user and help fix it first. Only after a clean deterministic pass should you continue.

### Step 2: Determine Scope
1. If given a REQ ID, find the associated branch and review its changes.
2. If given a branch name, review all changes on that branch vs `main`.
3. If no argument, review all changes on the current branch vs `main`.
4. Get the full diff by running in terminal: `git diff main...HEAD`
5. Read `.forge/context/rules/conventions.rules.md` and `.forge/context/rules/architecture.rules.md` via the codebase tool (skip if already in conversation).

### Step 3: Read All Changed Files
Use the codebase tool to read the complete current version of every changed file (not just the diff) to understand full context.

### Step 4: Check Lessons Learned
Use the codebase tool to search `.forge/knowledge/lessons/` with patterns matching the affected areas (e.g., `component:.*API/auth`). Read matched lesson files and flag any applicable lessons as findings.

### Step 5: Run Self-Review Checklist

#### Correctness
- Does the code do what the requirement/task specifies?
- Are all acceptance criteria met?
- Are edge cases handled (empty inputs, nulls, boundaries)?
- Are error paths handled properly?
- Any race conditions or async issues?

#### Convention Compliance
Read `.forge/context/rules/conventions.rules.md` first — it is the source of truth. Check the changed code against every rule it declares:
- Naming (files, types, variables, functions, constants, route paths) per the project's declared scheme
- Logging — uses the project's logger abstraction, not raw `console.log`
- Configuration — environment-specific values come from config, not hardcoded literals
- API response format — error and success shapes match the project's declared format

#### Architecture
Read `.forge/context/rules/architecture.rules.md` first. Check:
- Layering — routes/handlers don't bypass services; services don't bypass data-access layers
- Business logic location — sits in the correct layer per the architecture
- Dependency injection — components receive collaborators per the declared DI pattern

#### Testing
- New code has corresponding tests
- Tests cover error/failure paths, not just happy paths
- Mock files include all new exports
- No brittle assertions (exact string matching on long content, timestamp equality)
- Tests are deterministic (no flaky timing, no external dependencies)

#### Completeness
- No TODOs or FIXMEs left behind
- No commented-out code
- No debug logging accidentally left in
- All import paths resolve correctly

### Step 5: Surface Questions
Report a "Questions for the User" section covering:
- Ambiguous requirements
- Design tradeoffs made
- Assumptions made during implementation
- Deferred edge cases

If there are no questions, state: "No questions — implementation is unambiguous."

Do not proceed past this step until the user has answered any questions — their responses may change what needs to be fixed.

### Step 6: Fix or Defer
1. If Critical issues are found, fix them immediately.
2. If Major issues are found, ask the user whether to fix now or note for `#review`.
3. Minor issues can be listed for the user to decide.
4. After fixes, run tests via terminal to verify nothing broke.

### Step 7: Recommend Next Action
- If no issues or only minor ones: "Ready for `#review`"
- If fixes were applied: "Fixes applied. Re-run `#reflect` to verify, or proceed to `#review`"
- If blockers remain: "Address these issues before `#review`"

## Internal Reference
- **Incoming Skill Dependencies**: `#proceed`
- **Incoming Agent Dependencies**: *None*
- **Outgoing Skill Dependencies**: `#review`
- **Outgoing Agent Dependencies**: `#agents/reflector`
- **Resource Dependencies**: *None*
