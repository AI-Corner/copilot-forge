---
id: REQ-264
title: "Environment & Configuration Variable Mapping"
status: complete
deployable: true
created: 2026-05-04
updated: 2026-05-04
component: "Copilot Forge/context"
domain: "knowledge-management"
stack: ["markdown", "prompts"]
concerns: ["configuration", "developer-experience", "deployment-safety"]
tags: ["env-vars", "secrets", "documentation", "variables"]
---

## Description

Copilot Forge projects currently maintain context regarding architecture, flow, domain, and functional logic. However, they lack structured knowledge about environment variables, configuration properties (e.g., `application.yml`), frontend `.env` vars, and CI/CD secrets. 

This requirement introduces a new baseline knowledge artifact (`variables.md` or similar) that explicitly maps all configuration variables across the repository. This allows the AI agents and developers to instantly know which variables are used, where they are consumed, and for what purpose, preventing runtime crashes due to missing secrets and aiding in debugging.

## System Model

### Entities

| Entity | Field | Type | Constraints |
|--------|-------|------|-------------|
| Variable Knowledge | Key Name | string | Required, unique per scope |
| Variable Knowledge | Scope | string | e.g., 'frontend', 'backend', 'ci-cd' |
| Variable Knowledge | Purpose | string | Required |
| Variable Knowledge | Default Value | string | Optional |
| Variable Knowledge | Consumers | array(string) | Required, list of files/components using it |

## Business Rules

- [ ] BR-1: The architecture mapping phase MUST extract new environment variables and add them to the central variables context file.
- [ ] BR-2: PR reviews MUST flag any new variable usage in code that is not documented in the variables context file.
- [ ] BR-3: The knowledge file MUST NOT contain actual production secrets, only keys and safe default/example values.

## Acceptance Criteria

- [ ] A new template `templates/variables-template.md` is added to Copilot Forge.
- [ ] The `init` and `architect` prompts are updated to scan and map variables.
- [ ] A `.forge/context/variables.md` file is established in initialized projects.
- [ ] The `#forge-review` agent checks that new env vars are documented.

## External Dependencies

- None

## Assumptions

- Developers use standard mechanisms for variables (`.env`, `application.yml`, `process.env`, etc.).

## Open Questions

- [ ] Should variable extraction be a standalone agent, or bundled into `#forge-architect`?
- [ ] How do we handle dynamic variable keys if they are constructed programmatically?

## Out of Scope

- Automated secret rotation or secret injection into live environments.
