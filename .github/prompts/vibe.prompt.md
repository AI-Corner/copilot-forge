---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Fast, lightweight workflow for trivial changes (no heavy specs)
---

# vibe — Vibe Coding Workflow

You are implementing a small, isolated feature or tweak using the "Vibe Coding" methodology.

> **Ethos**: Fast, differential edits, run existing tests, atomic commit, minimal documentation. No new unit tests. No heavy specs.

## Input

Requirement: [provided by the user]

## Prerequisites

1. Use the codebase tool to verify `.forge/` exists.
2. Read `.forge/templates/vibe-template.md` (or `templates/vibe-template.md`).

## Instructions

### Phase 1: Implement (Vibe Mode)
1. Use the codebase tool to locate the relevant files for the requirement.
2. Make differential edits directly to implement the changes. Keep edits minimal and focused.
3. Do not write new unit tests.

### Phase 2: Verify
1. Run the project's existing test suite (e.g., `npm test`, `mvn test`) to ensure your changes did not break existing functionality.
2. If tests fail, fix the errors and re-run until they pass.

### Phase 3: Traceability (As-Built Doc)
1. Determine the next VIBE ID:
   ```bash
   mkdir -p .forge/specs/vibe 2>/dev/null
   VIBE_NUM=$(cat .forge/.next-vibe 2>/dev/null || echo "1")
   echo $((VIBE_NUM + 1)) > .forge/.next-vibe
   ```
2. Create `.forge/specs/vibe/VIBE-xxx-slug.md` (zero pad the number to 3 digits) using the `vibe-template.md`.
3. Fill in the Intent, Files Modified, and Verification sections.

### Phase 4: Continuous Commit
1. Immediately commit the changes:
   ```bash
   git add .
   git commit -m "feat(VIBE-xxx): <short description>"
   ```
2. Tell the user the Vibe coding is complete, the changes are committed, and the trace doc is saved.
