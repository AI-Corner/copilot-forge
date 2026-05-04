# Task 003: Update Architect Prompt

## Objective
Enhance `.github/prompts/architect.prompt.md` to ensure any new variables required by a feature are explicitly documented during the architecture phase.

## Implementation Steps
1. Edit `.github/prompts/architect.prompt.md`.
2. In the section defining the outputs (e.g., `architecture.md` and `tasks/*.md`), add a requirement: "If the new feature requires new environment variables, configuration properties, or secrets, you MUST define them in the architecture document and create a task to add them to `.forge/context/variables.md`."

## Acceptance Criteria
- `architect.prompt.md` forces the architect to consider and document new configuration properties.
