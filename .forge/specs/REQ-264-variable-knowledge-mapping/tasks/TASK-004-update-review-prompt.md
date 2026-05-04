# Task 004: Update Review Prompt

## Objective
Enhance `.github/prompts/review.prompt.md` to enforce the documentation of variables and prevent drift.

## Implementation Steps
1. Edit `.github/prompts/review.prompt.md`.
2. Add a specific check under the code review criteria.
3. Instruct the reviewer: "If the PR introduces new environment variables, configuration properties, or secrets (e.g., in `.env`, `application.yml`, `process.env`, `System.getenv()`), cross-reference them with `.forge/context/variables.md`. If a variable is used in code but not documented in the variables context, you MUST flag this as a failure for 'Documentation Drift'."

## Acceptance Criteria
- `review.prompt.md` actively acts as a gatekeeper against undocumented environment variables.
