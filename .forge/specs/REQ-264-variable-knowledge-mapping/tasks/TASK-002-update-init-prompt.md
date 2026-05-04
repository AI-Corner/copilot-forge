# Task 002: Update Init Prompt

## Objective
Enhance `.github/prompts/init.prompt.md` to instruct the AI to bootstrap `.forge/context/variables.md` during project initialization.

## Implementation Steps
1. Edit `.github/prompts/init.prompt.md`.
2. Add an instruction to the `Documentation Pipeline` or `Analysis` phase to scan for configuration files (e.g., `.env`, `application.yml`, `config.js`).
3. Instruct the AI to copy `templates/variables-template.md` to `.forge/context/variables.md`.
4. Instruct the AI to populate this new file with any existing variables it discovered during its scan, adhering to the template format.

## Acceptance Criteria
- `init.prompt.md` includes explicit steps for extracting environment variables and initializing `variables.md`.
