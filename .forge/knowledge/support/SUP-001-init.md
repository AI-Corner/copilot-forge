---
id: SUP-001
title: "Support: Project Initialization (#init)"
related_req: core-feature
created: 2026-05-04
updated: 2026-05-04
component: "init"
domain: "setup"
tags: ["init", "setup", "bootstrap", "context", "templates"]
---

## 1. Feature Overview
The `#init` prompt is used to bootstrap the Copilot Forge structure (`.forge/`) in a new or existing repository. It gathers project context and copies necessary templates to set up Spec-Driven Development.

## 2. Common User Queries & FAQ
- **Q: Why didn't `#init` create the `.github` directory?**
  **A:** `#init` only creates project-specific context in `.forge/`. The `.github` and `.vscode` folders must be copied manually from the toolkit repo or via `install.ps1`.
- **Q: Can I use `#init` on an existing project?**
  **A:** Yes. You can run `#init` and tell it to read your existing `/docs` folder or `README.md` to automatically generate the architecture and conventions.

## 3. Troubleshooting & Expected Behavior
| Scenario / Symptom | Expected Behavior | Workaround / Fix |
|-------------------|-------------------|------------------|
| Copilot says `#init` is not recognized. | `#init` must be invoked while the `.github/prompts/` folder is present. | Ensure `.github/` was copied to your project and `github.copilot.chat.experimental.prompt-files.enabled` is true in VS Code settings. |
| Overwritten templates. | `#init` should preserve custom templates. | If a template already exists in `.forge/templates/`, `#init` skips it. |

## 4. Known Limitations
- `#init` relies on VS Code's ability to create directories. Sometimes deeply nested folders require manual creation if the IDE extension host restricts it.
