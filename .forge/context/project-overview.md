# Project Overview — Copilot Forge

## What this project is

The **Copilot Forge** is a library of **prompts, agent checklists, and templates** that enable spec-driven development with **GitHub Copilot**. It is the source of `#spec`, `#architect`, `#proceed`, `#review`, `#bugfix`, and other prompts that consumer projects use to run their own spec-driven development pipelines inside VS Code with Copilot Chat.

This repo is itself a consumer of the toolkit only in the narrow sense that its own feature work is tracked in `.forge/specs/` — but it does NOT have the full consumer scaffold. No `.forge/knowledge/lessons/`, `.forge/bugs/`, or `.forge/templates/` directory inside this repo (those live in consumer projects after `#init`). The toolkit's canonical `templates/` directory at the repo root is what `#init` copies into consumer projects.

## Who uses it

- **Consumer project teams** copy `.github/` and `.vscode/` from this repo into their own project repos. Once copied, GitHub Copilot in VS Code automatically picks up `copilot-instructions.md` (global ethos) and the `.prompt.md` files (invokable via `#prompt-name` in Copilot Chat).
- **Toolkit maintainers** evolve the prompts, agent checklists, templates, and presets. REQs tracked here describe changes to the toolkit's own surface area: prompt behavior, template schemas, agent checklists, documentation.

## Install model

**Copy-based install.** For each project repo:

```powershell
# From inside your project repo (PowerShell):
Copy-Item -Recurse \path\to\copilot-forge\.github .
Copy-Item -Recurse \path\to\copilot-forge\.vscode .
```

After copying, the prompts live alongside the project's code and are read directly by VS Code's Copilot extension — no symlinks, no global registry, no publish step. When the toolkit is updated, pull the latest and re-copy `.github/` into each project repo. Use `#template-drift` to detect drift between a project's local `.forge/templates/` and the canonical `templates/` in this repo.

## Primary surface areas

| Surface | Files | Purpose |
|---|---|---|
| Prompts | `.github/prompts/*.prompt.md` | Markdown prompt files invoked via `#name` in Copilot Chat |
| Agent checklists | `.github/prompts/agents/*.prompt.md` | Specialized checklist agents referenced by `#review`, `#reflect`, `#architect`, etc. |
| Templates | `templates/*.md` | Canonical templates for requirements, bugs, lessons, tasks, assumptions |
| Presets | `presets/*.yml` | Stack-shaped starter configs that seed `.forge/config.yml` |
| Ethos | `ETHOS.md` + `.github/copilot-instructions.md` | 6 principles injected into every session via Copilot's instruction file |
| Docs | `README.md` | Install instructions and prompt catalog |

## How prompts are invoked

In Copilot Chat (VS Code), type `#<prompt-name>` to invoke a prompt:

```
#init           — bootstrap .forge/ in a new project
#spec Add login — write a requirement spec
#proceed REQ-001 — run the full pipeline for a REQ
#status         — show current state of all Copilot Forge work
```

Prompts run in `mode: agent` and have access to the `codebase`, `runCommand`, `changes`, and `terminalLastCommand` tools as declared in their frontmatter.

## Relationship to consumer projects

`#init` is the bridge: when a consumer project runs `#init`, it creates `.forge/context/`, `.forge/specs/`, `.forge/bugs/`, `.forge/knowledge/`, and `.forge/templates/` in that project, copying from this toolkit's `templates/` directory. After `#init`, the consumer project uses prompts that read from **its** `.forge/` structure — not the toolkit's.

The toolkit's own `.forge/` (containing only `specs/` and `context/`) is minimal by design. The toolkit tracks its own feature work starting with REQ-258.
