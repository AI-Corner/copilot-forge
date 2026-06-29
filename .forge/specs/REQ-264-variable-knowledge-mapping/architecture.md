# Architecture: Environment & Configuration Variable Mapping (REQ-264)

## Overview

This feature introduces a centralized variable registry within the Copilot Forge context (`.forge/context/variables.md`). AI agents (`#forge-init`, `#forge-architect`, `#forge-review`) will be upgraded to actively read, populate, and enforce this knowledge base to ensure robust management of environment variables and configuration properties across the repository.

## Component Changes

### 1. New Template: `templates/variables-template.md`
A standard markdown file that defines the structure for variable tracking. It will use categorized markdown tables to organize variables logically.

**Proposed Structure:**
- **Frontend Variables** (e.g., `VITE_*`, `REACT_APP_*`)
- **Backend Properties** (e.g., Spring Boot `application.yml`, Node `process.env`)
- **Infrastructure / Secrets** (e.g., CI/CD, Kubernetes Secrets, Helm Values)

*Standard Table Columns:*
| Variable Key | Type/Format | Default Value | Purpose | Consumers (Files/Components) |

### 2. Prompt Updates

**`.github/prompts/init.prompt.md`**:
- **Change**: When scaffolding a new repository or processing an existing one, the init agent must be instructed to scan for configuration files (`.env.example`, `application.yml`, `config.js`, etc.) and instantiate `.forge/context/variables.md` using the new template.

**`.github/prompts/architect.prompt.md`**:
- **Change**: When designing a feature, if new configuration keys or environment variables are required, the architect MUST explicitly define them and include instructions in the tasks to append them to `.forge/context/variables.md`.

**`.github/prompts/review.prompt.md`**:
- **Change**: During code review, the reviewer must be instructed to check the code diff for new variable usage (e.g., `process.env.*`, `System.getenv()`, `@Value`). If a referenced variable is not documented in `.forge/context/variables.md` or added in the current PR, it must flag it as an architecture/documentation drift error.

## Technical Considerations

- **Security Constraint**: The templates and prompts MUST explicitly instruct the AI *never* to write real production secrets to `variables.md`. It should only contain the key names and safe, descriptive dummy/default values.
- **Drift Prevention**: The `#forge-review` prompt acts as the primary gatekeeper to prevent the code's configuration surface from drifting away from the documented variable state.
