---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Bootstrap .forge/ structure in a new project repo
---

# init — Bootstrap Copilot Forge Structure

You are setting up the `.forge/` directory structure for spec-driven development in this project.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Target directory: [provided by the user — defaults to the current workspace root if omitted]

## Instructions

### Step 1: Determine Target Directory
1. If the user gave a path, use that. Otherwise use the workspace root.
2. Check if `.forge/` already exists. If it does, report what's already there and ask whether to reinitialize or fill gaps only.

### Step 2: Gather Project Context
Ask the user for the following (skip any already known from existing files like `README.md`, `package.json`, or project documentation):
1. **Project name** — What is this project called?
2. **What it does** — One paragraph description
3. **Tech stack** — Languages, frameworks, databases, cloud providers
4. **Project scope** — What's in scope vs out of scope
5. **Key architectural patterns** — Layered? Microservices? Monolith?

If a `README.md` or `package.json` exists, read it via the codebase tool and extract this info automatically — confirm with the user instead of asking from scratch.

### Step 3: Migration Check & Directory Structure

1. **Migration Check**: If `.forge/context/architecture.md` exists, migrate it to the v2 layout:
   - Create `rules/` and `corpus/` inside `.forge/context/`.
   - Move `architecture.md`, `conventions.md`, `variables.md`, and `deployment.md` to `corpus/`.
   - Read the newly moved files and extract their core directives to create `rules/architecture.rules.md` and `rules/conventions.rules.md`.
   - Create `rules/security.rules.md` and `rules/deployment.rules.md` based on project configuration.

2. **New Setup**: If `.forge/` does not exist, use the terminal to create:
```
.forge/
  context/
    project-overview.md
    taxonomy.md
    rules/
      architecture.rules.md
      conventions.rules.md
      security.rules.md
      deployment.rules.md
    corpus/
      architecture.md
      conventions.md
      variables.md
      deployment.md
  specs/
    .gitkeep
  bugs/
    .gitkeep
  knowledge/
    assumptions/
      .gitkeep
    lessons/
      .gitkeep
    support/
      .gitkeep
    inbox/
      .gitkeep
    archive/
      .gitkeep
  templates/
    assumption-template.md
    bug-template.md
    lesson-template.md
    requirement-template.md
    support-template.md
    task-template.md
    variables-template.md
    manual-qa-template.md
    deployment-template.md
    env-local-template.env
    inbox-template.md
```

Copy templates from `templates/` at the toolkit repo root (the canonical location). If a local copy already exists in the consumer project's `.forge/templates/`, preserve it — do not overwrite customizations.

### Step 4: Populate Context Files

**project-overview.md** — fill in based on user input:
```markdown
# {Project Name} — Project Overview

*Navigation: [Architecture Rules](rules/architecture.rules.md) | [Conventions Rules](rules/conventions.rules.md) | [Taxonomy](taxonomy.md)*

## What It Does
{description}

## Tech Stack
{tech stack table or list}

## Project Scope
{in scope / out of scope}
```

**corpus/architecture.md** — initial structure:
```markdown
# {Project Name} — Architecture

*Navigation: [Project Overview](../project-overview.md) | [Conventions Rules](../rules/conventions.rules.md) | [Taxonomy](../taxonomy.md)*

## System Diagram
{Mermaid flowchart or diagram mapping the core system architecture}

## Layers
{description of architectural layers}

## Key Patterns
{important patterns used in the codebase}

## ADRs
(Add architectural decision records here as decisions are made)
```

**rules/architecture.rules.md** — derived from the architecture:
```markdown
# Architecture Rules
1. Extract the strict architectural constraints from the corpus and list them here.
```

**corpus/conventions.md** — based on project analysis:
```markdown
# {Project Name} — Conventions

*Navigation: [Project Overview](../project-overview.md) | [Architecture Rules](../rules/architecture.rules.md) | [Taxonomy](../taxonomy.md)*

## File Organization
{directory structure}

## Naming
{naming conventions per language}

## Testing
{test framework, conventions, coverage requirements}

## Error Handling
{error handling patterns}

## Git Conventions
{branch naming, commit messages, PR process}
```

**rules/conventions.rules.md** — derived from conventions:
```markdown
# Convention Rules
1. Extract the strict coding rules from the conventions corpus and list them here.
```

**corpus/variables.md** — environment and configuration tracking:
1. Copy `templates/variables-template.md` to `.forge/context/corpus/variables.md`.
2. Scan the repository for configuration files (e.g., `.env.example`, `application.yml`, `config.js`, `helm/values.yaml`).
3. Extract existing variables and populate the tables in `.forge/context/corpus/variables.md`. 
4. **CRITICAL**: Do NOT extract or write actual production secrets. Use dummy values or the safe default values found in `.example` files.

**corpus/deployment.md** — deployment flow tracking:
1. Copy `templates/deployment-template.md` to `.forge/context/corpus/deployment.md`.
2. Scan the repository for deployment configurations (e.g., `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `Dockerfile`, `helm/`, `terraform/`, `package.json` scripts).
3. Extract the existing deployment workflow and populate `.forge/context/corpus/deployment.md`. If no deployment mechanism is found, note it as "Not configured".

**rules/security.rules.md** and **rules/deployment.rules.md**:
Create these with basic rules (e.g., no hardcoded secrets, canary deployment required) based on the extracted deployment patterns.

**Support Documentation** — capturing miscellaneous context:
If the user provides external documentation (e.g., a `/docs` folder) during initialization and you extract valuable context that does not neatly fit into `architecture.md`, `conventions.md`, or `project-overview.md`, generate a support document for it.
1. Use `templates/support-template.md`.
2. Save it to `.forge/knowledge/support/SUP-xxx-slug.md` (e.g., `SUP-001-legacy-api-quirks.md`).
3. Update or create `.forge/knowledge/support/_index.md` to hyperlink to the new document.

### Step 5: Update .gitignore
Add to `.gitignore` (create if it doesn't exist):
```
# Copilot Forge worktrees
.worktrees/

# Copilot Forge per-project counters
.forge/.next-bug
.forge/.next-lesson
.forge/.next-req
.forge/.next-sup
.forge/.next-qa

# Local Secrets & Tokens
.forge/.env.local

# VS Code local settings
.vscode/settings.local.json
```

### Step 6: Scaffold Retrieval Taxonomy
Copy `templates/taxonomy-template.md` to `.forge/context/taxonomy.md` (skip if it already exists — preserve customizations).

Advise the user: "Open `.forge/context/taxonomy.md` and customize the example values for this codebase."

### Step 7: Scaffold Cross-Repo Config (Optional)
Ask the user: "Will this repo ever share features with other repos (e.g., an API + a web frontend + a mobile app)? If yes, you'll need a `.forge/config.yml`."

If yes and `.forge/config.yml` doesn't already exist, copy `templates/config-template.yml` to `.forge/config.yml` and advise the user to fill in all `<placeholder>` values.

### Step 8: Scaffold Local Secrets
Check if `.forge/.env.local` exists. If not, copy `templates/env-local-template.env` to `.forge/.env.local`. Advise the user to open this file and configure their `GITLAB_TOKEN` and IDs if they plan to use `#issue_epic_creation`.

### Step 9: Summary
1. Display the created directory structure
2. Explain the Copilot Forge workflow: `#spec` → `#validate` → `#architect` → `#validate` → `#issue_epic_creation` → implement...
3. Suggest next step: "Run `#spec` to write your first requirement spec."

## Internal Reference
- **Incoming Skill Dependencies**: *None*
- **Incoming Agent Dependencies**: *None*
- **Outgoing Skill Dependencies**: *None*
- **Outgoing Agent Dependencies**: *None*
- **Resource Dependencies**: `adr-template.md`, `assumption-template.md`, `bug-template.md`, `deployment-template.md`, `env-local-template.env`, `lesson-template.md`, `requirement-template.md`, `support-template.md`, `task-template.md`, `taxonomy-template.md`, `variables-template.md`
