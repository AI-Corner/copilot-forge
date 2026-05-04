# Copilot Forge

Prompts, checklists, and templates for spec-driven development with **GitHub Copilot**. Stack-agnostic at the core, with optional preset configs for common stacks (Java Spring Boot + PostgreSQL + AKS, React + AKS, etc.).

## What's Included

## Changelog & Recent Updates
- **v1.4.0**: Introduced **Visual Architecture** generation. Both `#init` and `#architect` now mandate native Mermaid sequence diagrams and flowcharts for project and feature-level architecture documentation.
- **v1.3.1**: Refined the security gate to be **Interactive**, allowing users to flag false positives before committing. Added a standalone `#security_scan` prompt.
- **v1.3.0**: Integrated a **Pre-Commit Security Scan** into `#wrapup` to detect and block hardcoded credentials/secrets.
- **v1.2.0**: Added automated **Support Documentation** generation (via `#wrapup`) and explicitly segregated Application vs. Infrastructure variables in `variables-template.md`.
- **v1.1.0**: Introduced `#tdd` prompt for Test-Driven Development enforcing the Red-Green-Refactor cycle.
- **v1.0.0**: Initial Copilot Forge release (formerly ADLC).

### Prompts

Invoke any prompt from Copilot Chat by typing `#<prompt-name>`:

| Prompt | Description |
|--------|-------------|
| `#init` | Bootstrap `.forge/` structure in a new repo |
| `#spec` | Write requirement specs from feature requests |
| `#architect` | Design architecture and break requirements into tasks |
| `#validate` | Validate any Copilot Forge phase output before advancing |
| `#issue_epic_creation` | Sync local REQs and Tasks to GitLab as Epics and Issues |
| `#tdd` | Generate failing test suites before implementation (Red-Green-Refactor) |
| `#proceed` | End-to-end pipeline: validate → architect → tdd → implement → reflect → review → PR → wrapup |
| `#sprint` | Sequential pipeline orchestrator — run multiple `#proceed` sessions across REQs |
| `#reflect` | Post-implementation self-review before formal review |
| `#review` | Multi-dimension code review (correctness, quality, architecture, tests, security) |
| `#canary` | Canary deployment with smoke tests — deploy zero-traffic revision and promote on success |
| `#wrapup` | Close out a feature — commit, merge, deploy, update artifacts |
| `#bugfix` | Streamlined bug fix workflow |
| `#status` | Show current state of all Copilot Forge work |
| `#analyze` | Codebase health audit |
| `#security_scan` | Interactive pre-commit secret and credential audit |
| `#optimize` | API cost & performance scanner |
| `#template-drift` | Detect drift between a project's local `.forge/templates/` and the canonical toolkit templates |

### Agent Reference Checklists

These live in `.github/prompts/agents/` and are referenced inline by `#review`, `#reflect`, `#analyze`, `#optimize`, and `#architect`. They are not invoked directly.

| Checklist | Used by |
|-----------|---------|
| `reflector` | `#reflect`, `#proceed` Phase 5 |
| `correctness-reviewer` | `#review`, `#proceed` Phase 5 |
| `quality-reviewer` | `#review`, `#proceed` Phase 5 |
| `architecture-reviewer` | `#review`, `#proceed` Phase 5 |
| `test-auditor` | `#review`, `#analyze`, `#proceed` Phase 5 |
| `security-auditor` | `#review`, `#analyze`, `#proceed` Phase 5 |
| `feature-tracer` | `#architect` |
| `architecture-mapper` | `#architect` |
| `integration-explorer` | `#architect` |
| `convention-auditor` | `#analyze` |
| `code-quality-auditor` | `#analyze` |
| `api-cost-scanner` | `#optimize` |
| `db-perf-scanner` | `#optimize` |
| `latency-scanner` | `#optimize` |
| `task-implementer` | `#proceed` Phase 4 |

### Templates

- `requirement-template.md` — Requirement spec template
- `task-template.md` — Technical task template
- `bug-template.md` — Bug report template
- `assumption-template.md` — Validated-assumption knowledge entry
- `lesson-template.md` — Lesson-learned knowledge entry
- `support-template.md` — Automated Support Documentation / FAQ knowledge entry
- `variables-template.md` — Environment & Config variables tracking

### Presets

Stack-shaped starter configs that seed `.forge/config.yml` for common stacks. See [`presets/`](presets/) for the current list.

## How it works

The toolkit is split into two layers:

1. **The toolkit repo** (this repo) — generic prompts, checklists, and templates that work for any stack. Copy `.github/` and `.vscode/` into each project repo to install.
2. **Per-project `.forge/` directory** — lives in each code repo. Holds the project's specs, architecture, conventions, and a `config.yml` that declares the project's stack, deploy targets, and repo layout. **All project-specific values live here**, never in the toolkit.

Prompts read `.forge/config.yml` at runtime to resolve project-specific things (GCP project IDs, iOS device names, Cloud Run service names, etc.) — nothing is hardcoded in the prompts themselves.

## Setup

### 1. Clone this repo

```bash
git clone https://github.com/<owner>/copilot-forge.git
```

### 2. Copy the Copilot files into your project

**Option A: Automated Setup (Windows)**
Run the installer script from the root of this toolkit:
```powershell
.\install.ps1 -TargetDir \path\to\your\project
```

**Option B: Manual Setup**
For each project repo you want to use Copilot Forge in:

```bash
# From inside your project repo:
cp -r /path/to/copilot-forge/.github .
cp -r /path/to/copilot-forge/.vscode .
cp -r /path/to/copilot-forge/templates .   # optional — for local template copies
```

Or on Windows (PowerShell):

```powershell
Copy-Item -Recurse \path\to\copilot-forge\.github .
Copy-Item -Recurse \path\to\copilot-forge\.vscode .
```

> **Why copy instead of symlink?** Copilot reads prompt files directly from the workspace — symlinks across repos are not reliably followed by the VS Code extension host.

### 3. Enable Copilot prompt files

The `.vscode/settings.json` included in this toolkit already enables prompt files. If you have your own settings, make sure these are set:

```json
{
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "github.copilot.chat.experimental.prompt-files.enabled": true
}
```

### 4. Initialize a project

Open Copilot Chat in the project repo and type:

```
#init
```

> **💡 Tip for existing projects**: If you have existing architecture diagrams, infra files, or documentation, you can feed them directly into the initialization process by attaching them or giving explicit instructions:
> `#init please review the /docs folder and #file:infra/main.tf before generating the context files`

This bootstraps the `.forge/` directory with project-specific context, specs, and copies of the templates.

### 5. Configure for your stack

Pick a preset that matches your stack and copy it to `.forge/config.yml`:

```powershell
# PowerShell — list available presets
ls presets/

# Backend / API repo (Java Spring Boot + PostgreSQL + AKS):
Copy-Item presets\springboot-postgres-aks.yml .forge\config.yml

# Frontend / web repo (React + AKS):
Copy-Item presets\react-aks.yml .forge\config.yml
```

Replace every `<placeholder>` with a real value.

If no preset matches, copy the bare template instead:

```bash
cp templates/config-template.yml .forge/config.yml
```

Single-repo projects without a backend can leave the file absent — every prompt falls back to single-repo behavior in that case.

## Workflow

```
#spec → #validate → #architect → #validate → implement → #reflect → #review → merge → #wrapup
```

Or use `#proceed` to run the full pipeline automatically for a single REQ.

For bugs: `#bugfix` (report → analyze → fix → verify → ship)

For multi-REQ batches: `#sprint` (runs multiple `#proceed` pipelines sequentially)

### Resolving Drift (Incremental Analysis)

If you or a teammate make manual code changes outside of the Copilot Forge pipeline (or via a `git pull`), your `.forge/context/` documentation may drift out of sync. 

To resolve this automatically, just run `#analyze`.
Copilot Forge uses a highly efficient **Incremental Analysis** engine. It stores the commit hash from its last run in `.forge/.last-analyzed-commit`. When you run `#analyze`, it uses `git diff` to identify exactly which files were added or modified since the last run. It then audits *only* those new files and automatically updates `architecture.md` and `conventions.md` to perfectly match the new codebase reality without needing to rescan the entire project.

## Project Structure

After `#init`, each code repo will have:

```
.forge/
  config.yml         # Project's stack, deploy config, and (optional) sibling repo layout
  context/           # Project-specific architecture, conventions, overview
  specs/             # Requirement docs, architecture docs, tasks
  knowledge/         # Assumptions validated, lessons learned
  templates/         # Copies of templates (from this toolkit)
```

The toolkit repo contains the **process** (prompts + templates). Each code repo contains the **artifacts** (specs, architecture, knowledge).

## Cross-Repo REQs

Some features span multiple repos (e.g., a feature that touches a backend API, a web frontend, and a mobile app at the same time). The toolkit supports these via the optional `repos:` block in `.forge/config.yml`.

### Key concept: "primary" is per-REQ

There is no fixed "primary repo." Whichever repo you invoke `#proceed` (or `#bugfix`) from becomes the primary for that REQ — it holds the spec, tasks, and `pipeline-state.json` for that work. A different REQ that originates in a sibling repo makes that sibling the primary. Every repo that may originate REQs gets its own `.forge/` structure and its own `config.yml`; the configs are **mirror images** of each other (each repo marks itself `primary: true` and lists the others as siblings).

### config.yml shape

```yaml
repos:
  api:
    primary: true       # only in this repo's config
  infrastructure:
    path: ../infrastructure
  app:
    path: ../app
  web:
    path: ../web

merge_order:            # default Phase 8 merge sequence
  - infrastructure
  - api
  - app
  - web

services:               # consumed by /canary, keyed by repo id
  api:
    cloud_run_service: api
    region: us-central1
    image_path: us-central1-docker.pkg.dev/<gcp-project>/api/api
  # (infrastructure has no service entry — it deploys via Terraform)
```

See [`templates/config-template.yml`](templates/config-template.yml) for the full annotated template (including `project:`, `stack:`, `gcp:`, and `ios:` sections).

### What changes when cross-repo is configured

- `#proceed` creates a worktree in every touched sibling, routes tasks by `repo:` frontmatter, opens one PR per repo, and merges in `merge_order`
- `#architect` requires a `repo:` field on every task it generates
- `#validate` checks that `repo:` values resolve to configured repo ids and that task files stay in their declared repo
- `#wrapup` walks `mergeOrder` to land PRs in order and cleans up worktrees across every touched repo
- `#canary` resolves service metadata from `services:` instead of a hardcoded table
- `#status` reports cross-repo activity (REQs originating elsewhere that touch this repo)
- `#sprint` delegates cross-repo mechanics to each `#proceed`; one sprint still originates all REQs from the invoking repo
- `#bugfix` supports cross-repo bugs via `repo:` or `touched_repos:` on the bug frontmatter

### Single-repo mode (default)

If no `config.yml` exists or it has only a single `repos:` entry, every prompt falls back to single-repo behavior. Existing projects are unaffected until they opt in by creating `config.yml`.

## Stack support

The toolkit's workflow is stack-agnostic. Prompts that need to do stack-specific things (deploy a Cloud Run service, push a build to an iOS device, etc.) read `.forge/config.yml` to learn what your stack is and what concrete values to use.

| Capability | Where the prompt checks | What you fill in |
|---|---|---|
| Deploy confirmation (`#bugfix`, `#wrapup`) | `stack.backends` includes `cloud-run` | `gcp.staging_project`, `gcp.production_project` |
| AKS deploy confirmation (`#bugfix`, `#wrapup`) | `stack.backends` includes `k8s` | `aks.cluster_name`, `aks.resource_group`, `services.<id>.namespace` |
| Canary deploys (`#canary`) | `services:` block | service name, region, image path per repo (Cloud Run) |
| AKS canary / rollout verification (`#canary`) | `stack.backends` includes `k8s` | `services.<id>.deployment_name`, `services.<id>.health_check_path` |
| iOS device deploys (`#bugfix`, `#wrapup`) | `stack.frontends` includes `ios` | `ios.deploy_targets`, `ios.deploy_command` |
| Convention checking (`#review`, `#reflect`) | `.forge/context/conventions.md` | declare your project's naming, logging, and API conventions |

If you want to add support for a new stack (e.g., AWS Lambda backends, Android device deploys), edit the relevant prompt to handle the new `stack.*` value and document it in [`templates/config-template.yml`](templates/config-template.yml). PRs welcome.

## Updating

Pull the latest toolkit and re-copy the `.github/` directory into each project repo:

```bash
cd /path/to/copilot-forge
git pull

# Then in each project repo:
cp -r /path/to/copilot-forge/.github .
```

Use `#template-drift` in any project to check whether local `.forge/templates/` copies are out of date with the canonical `templates/` in this toolkit repo.

## Contributing

This is published as a generic toolkit you can fork or contribute back to. Patches that add presets, support new stacks, or sharpen workflows for stacks already supported are all welcome.

## FAQ

Got questions about token consumption, external LLMs, or documentation drift? Check out the [Frequently Asked Questions (FAQ)](FAQ.md).

