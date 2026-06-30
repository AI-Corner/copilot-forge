# Copilot Forge

Prompts, checklists, and templates for spec-driven development with **GitHub Copilot**. Stack-agnostic at the core, with optional preset configs for common stacks (Java Spring Boot + PostgreSQL + AKS, React + AKS, etc.).

## What's Included

## Changelog & Recent Updates
- **v2.9.0** *(BREAKING)*: **Prompt Namespace Prefix**. All 48 prompt files renamed from `<name>.prompt.md` to `forge-<name>.prompt.md` (e.g., `#spec` → `#forge-spec`, `#review` → `#forge-review`). Typing `#forge-` in VS Code Copilot Chat now instantly filters to only Forge commands, eliminating popup clutter in multi-repo workspaces. Underscores normalized to hyphens (`security_scan` → `forge-security-scan`, `issue_epic_creation` → `forge-issue-epic-creation`). All 1,100+ internal cross-references updated across prompts, documentation, templates, scripts, graph data, and `.forge/` project context files.
- **v2.8.0**: Added **Computational vs. Inferential Sensor Split** (Feature 17). Formalized the verification phase in `#forge-proceed` into two parts. Fast, deterministic computational tools (`lint-gate`, `test-gate`, `build-gate`, etc.) run first. Only if they pass perfectly do we spend tokens running the slower, LLM-based inferential reviewers (`correctness-reviewer`, `spec-adherence`, etc.). All agents in `.github/prompts/agents/` are now cleanly organized into `computational/` and `inferential/` subdirectories.
- **v2.7.0**: Added **Process Discipline Guides** (Feature 16). The toolkit now includes explicit behavioral rules (Iron Laws and Process Guides) to prevent hallucinations, constrain scope, and enforce validation rules. `#forge-init` automatically scaffolds `.forge/context/rules/process/` in new projects.
- **v2.6.0**: Added **Codebase State Document** (Feature 20). The toolkit now empirically tracks your project's health and tech stack. `#forge-init` generates `codebase-state.md` with tool versions and scaffolds `quality-radar.md` and `code-debt.md`. `#forge-analyze` updates the scorecard and logs technical debt. `#forge-review` appends deferred minor issues to the debt ledger so they aren't lost.
- **v2.5.0**: Added **Drift Sensor** (Feature 19). Introduced a new lightweight, read-only `#forge-check-drift` prompt to continuously check convention compliance during active development. Hooked into `#forge-proceed` Phase 4 to automatically flag convention deviations (🔴 IRON LAW, 🟡 GOLDEN PATH, 🔵 RULE) every 3 tasks, preventing architectural drift from compounding before `#forge-review` catches it.
- **v2.4.0**: Added **Corpus/Guide Split** (Feature 14) and **Learning Flywheel** (Feature 15). Context files are now split into short, directive `rules/` (always loaded) and long-form `corpus/` (loaded on demand) under `.forge/context/` for optimized token usage. Three pipeline prompts (`#forge-reflect`, `#forge-review`, `#forge-wrapup`) now auto-capture learning candidates to a new `.forge/knowledge/inbox/`. Added `#forge-synthesize` to process inbox candidates into permanent rules/lessons/ADRs, and `#forge-prune` to periodically garbage-collect stale knowledge. `#forge-init` updated with auto-migration for existing projects.
- **v2.3.0**: Added **Dynamic Dependency Graph Visualization**. Refactored all internal prompt dependencies to an intent-based 5-category system (Skills vs. Agents). Automatically generates an interactive D3.js graph to explore the toolkit's architecture. View the graph locally by opening [docs/graph/index.html](docs/graph/index.html).
- **v2.2.0**: Added **Forge Admin Prompt (`#forge-admin`)**. A maintenance control plane for governing Forge's own prompts, agents, templates, and scripts. Supports five actions (`audit`, `patch`, `standardize`, `deprecate`, `index`) with mandatory dependency graph scanning before any write operation to prevent silent pipeline breakage. All modifications are tracked via lightweight REQ specs for audit traceability.
- **v2.1.0**: Added **Harness Engineering: Deterministic Pipeline**. Replaced honor-system LLM guardrails with hard, deterministic phase gates (`forge-gate.ps1`). Introduced an autonomous test runner loop (`forge-test.ps1`), an active context snapshot generator to prevent drift (`forge-context.ps1`), execution metrics tracking in `pipeline-state.json`, and a structured failure taxonomy for orchestrating agents.
- **v2.0.0**: Added **Project Knowledge Query & Capture (`#forge-query`)**. Replaces `#learn` with a hybrid agent that can discuss project history, answer questions using `.forge/context`, and optionally capture new lessons, ADRs, assumptions, and support docs when a new conclusion is reached.
- **v1.9.0**: Added **Hybrid ADR Support (Architecture Decision Records)**. Introduced a new `adr-template.md` and updated `#forge-architect` and `#forge-wrapup` prompts to support logging minor feature-level decisions directly in the local architecture doc, while automatically promoting global/reusable standards to standalone ADR files in `.forge/knowledge/decisions/`.
- **v1.8.0**: Introduced **Vibe Coding Workflow**. Added `#forge-vibe` prompt for lightweight, low-overhead changes and an intelligent workflow router in `#forge-spec` to automatically suggest `#forge-vibe` for tasks without cross-boundary impact or unit test requirements.
- **v1.7.0**: Added **Token Usage Estimator**. New `#forge-token-estimate` prompt and `.\scripts\token-estimate.ps1` script estimate session token consumption by phase using a `ceil(bytes/4)` approximation. Results are written to `pipeline-state.json` and surfaced in the `#forge-wrapup` ship summary under Metrics.
- **v1.6.0**: Added **Deployment Flow Context Tracking**. `#forge-init` now scans for CI/CD configurations and scaffolds a `deployment.md` document to ensure agents understand existing deployment workflows.
- **v1.5.0**: Adopted **System-First Specifications (Zachman 5W1H Framework)**. Upgraded `requirement-template.md` and `#forge-spec` prompt to enforce rigid boundaries (What, Who, When, Where, Why, How) to eliminate ambiguity from user stories.
- **v1.4.0**: Introduced **Visual Architecture** generation. Both `#forge-init` and `#forge-architect` now mandate native Mermaid sequence diagrams and flowcharts for project and feature-level architecture documentation.
- **v1.3.1**: Refined the security gate to be **Interactive**, allowing users to flag false positives before committing. Added a standalone `#forge-security-scan` prompt.
- **v1.3.0**: Integrated a **Pre-Commit Security Scan** into `#forge-wrapup` to detect and block hardcoded credentials/secrets.
- **v1.2.0**: Added automated **Support Documentation** generation (via `#forge-wrapup`) and explicitly segregated Application vs. Infrastructure variables in `variables-template.md`.
- **v1.1.0**: Introduced `#forge-tdd` prompt for Test-Driven Development enforcing the Red-Green-Refactor cycle.
- **v1.0.0**: Initial Copilot Forge release (formerly ADLC).

### Prompts & Usage Guide

For a complete reference of every Copilot Forge prompt, including what they do, when to call them, and where they fit in the workflow, see the **[Prompt Usage Guide](PROMPT_USAGE.md)**.

You can also explore the **[Interactive Dependency Graph](docs/graph/index.html)** to visually trace how the various skills and agents orchestrate each other under the hood.

Invoke any prompt from Copilot Chat by typing `#<prompt-name>` (e.g., `#forge-init`, `#forge-spec`, `#forge-proceed`).

### Templates

- `requirement-template.md` — Requirement spec template
- `task-template.md` — Technical task template
- `bug-template.md` — Bug report template
- `adr-template.md` — Architecture Decision Record (ADR) global standard entry
- `assumption-template.md` — Validated-assumption knowledge entry
- `lesson-template.md` — Lesson-learned knowledge entry
- `support-template.md` — Automated Support Documentation / FAQ knowledge entry
- `variables-template.md` — Environment & Config variables tracking
- `deployment-template.md` — CI/CD and deployment flow tracking
- `inbox-template.md` — Learning candidate for the knowledge flywheel inbox

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
.\scripts\install.ps1 -TargetDir \path\to\your\project
```

**Option B: Manual Setup**
For each project repo you want to use Copilot Forge in:

```bash
# From inside your project repo:
cp -r /path/to/copilot-forge/.github .
cp -r /path/to/copilot-forge/.vscode .
cp -r /path/to/copilot-forge/templates .forge/templates   # optional — for local template copies
```

Or on Windows (PowerShell):

```powershell
Copy-Item -Recurse \path\to\copilot-forge\.github .
Copy-Item -Recurse \path\to\copilot-forge\.vscode .
```

> **Why copy instead of symlink?** Copilot reads prompt files directly from the workspace — symlinks across repos are not reliably followed by the VS Code extension host.

### 3. Upgrading Copilot Forge

To seamlessly upgrade your project to the latest version of Copilot Forge without losing your `.forge` state or custom templates, use the `update.ps1` script from the root of this toolkit directory. This script is designed to be non-destructive and automatically backs up your existing configuration before making changes.

**1. Run a Health Check (Recommended)**
Preview the version gap, check for template drift, and see protected file status without modifying any files:
```powershell
.\scripts\update.ps1 -TargetDir \path\to\your\project -HealthOnly
```

**2. Preview the Update (Optional)**
See exactly which files will be added, updated, or skipped without actually writing to disk:
```powershell
.\scripts\update.ps1 -TargetDir \path\to\your\project -DryRun
```

**3. Perform the Update**
```powershell
.\scripts\update.ps1 -TargetDir \path\to\your\project
```

**4. Customizing Paths (Multi-Component Repos)**
If your `.forge` structure or prompts are nested inside a multi-component repo, you can override the default target paths:
```powershell
.\scripts\update.ps1 -TargetDir \path\to\your\project `
    -PromptsDir \path\to\your\project\libs\backend\.github\prompts `
    -TemplatesDir \path\to\your\project\libs\backend\.forge\templates
```
Available path parameters: `-GithubDir`, `-PromptsDir`, `-TemplatesDir`, `-ScriptsDir`, `-VscodeDir`.

After the script completes, open Copilot Chat in your project and run `#forge-init` to safely apply any new `.forge` directory structure or context migrations.

### 4. Enable Copilot prompt files

The `.vscode/settings.json` included in this toolkit already enables prompt files. If you have your own settings, make sure these are set:

```json
{
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "github.copilot.chat.experimental.prompt-files.enabled": true
}
```

### 5. Initialize a project

Open Copilot Chat in the project repo and type:

```
#forge-init
```

> **💡 Tip for existing projects**: If you have existing architecture diagrams, infra files, or documentation, you can feed them directly into the initialization process by attaching them or giving explicit instructions:
> `#forge-init please review the /docs folder and #file:infra/main.tf before generating the context files`

This bootstraps the `.forge/` directory with project-specific context, specs, and copies of the templates.

### 6. Configure for your stack

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
#forge-spec → #forge-validate → #forge-architect → #forge-validate → implement → #forge-reflect → #forge-review → merge → #forge-wrapup → #forge-synthesize (periodically)
```

Or use `#forge-proceed` to run the full pipeline automatically for a single REQ.

For bugs: `#forge-bugfix` (report → analyze → fix → verify → ship)

For multi-REQ batches: `#forge-sprint` (runs multiple `#forge-proceed` pipelines sequentially)

### Resolving Drift (Incremental Analysis)

If you or a teammate make manual code changes outside of the Copilot Forge pipeline (or via a `git pull`), your `.forge/context/` documentation may drift out of sync. 

To resolve this automatically, just run `#forge-analyze`.
Copilot Forge uses a highly efficient **Incremental Analysis** engine. It stores the commit hash from its last run in `.forge/.last-analyzed-commit`. When you run `#forge-analyze`, it uses `git diff` to identify exactly which files were added or modified since the last run. It then audits *only* those new files and automatically updates `architecture.md` and `conventions.md` to perfectly match the new codebase reality without needing to rescan the entire project.

### Process Discipline Guides

While workflows dictate *what* to do, **Process Discipline Guides** dictate *how* the AI behaves. To prevent AI hallucinations, scope creep, and dangerous edits, Copilot Forge natively enforces behavioral boundaries through rule files in `.forge/context/rules/process/`. 

These guides implement a tiered severity system:
- 🔴 **IRON LAW**: Non-negotiable rules (e.g., "No proceeding without acceptance criteria", "No silent overwrites").
- 🟡 **GOLDEN PATH**: Strong defaults that require explicit justification to break (e.g., "Verify references exist before using them").
- 🔵 **RULE**: Standard operating procedures (e.g., "One concern per commit").

`#forge-init` automatically scaffolds these process guides into any new project to ensure the AI behaves responsibly from day one.

## Project Structure

After `#forge-init`, each code repo will have:

```
.forge/
  config.yml         # Project's stack, deploy config, and (optional) sibling repo layout
  context/           # Project-specific architecture, conventions, overview
    rules/           # Short, directive rules (always loaded by agents)
    corpus/          # Long-form reference docs (loaded on demand)
  specs/             # Requirement docs, architecture docs, tasks
  knowledge/         # Assumptions validated, lessons learned
    inbox/           # Raw learning candidates from pipeline auto-capture
    archive/         # Pruned or rejected knowledge
  templates/         # Copies of templates (from this toolkit)
```

The toolkit repo contains the **process** (prompts + templates). Each code repo contains the **artifacts** (specs, architecture, knowledge).

## Cross-Repo REQs

Some features span multiple repos (e.g., a feature that touches a backend API, a web frontend, and a mobile app at the same time). The toolkit supports these via the optional `repos:` block in `.forge/config.yml`.

### Key concept: "primary" is per-REQ

There is no fixed "primary repo." Whichever repo you invoke `#forge-proceed` (or `#forge-bugfix`) from becomes the primary for that REQ — it holds the spec, tasks, and `pipeline-state.json` for that work. A different REQ that originates in a sibling repo makes that sibling the primary. Every repo that may originate REQs gets its own `.forge/` structure and its own `config.yml`; the configs are **mirror images** of each other (each repo marks itself `primary: true` and lists the others as siblings).

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

- `#forge-proceed` creates a worktree in every touched sibling, routes tasks by `repo:` frontmatter, opens one PR per repo, and merges in `merge_order`
- `#forge-architect` requires a `repo:` field on every task it generates
- `#forge-validate` checks that `repo:` values resolve to configured repo ids and that task files stay in their declared repo
- `#forge-wrapup` walks `mergeOrder` to land PRs in order and cleans up worktrees across every touched repo
- `#forge-canary` resolves service metadata from `services:` instead of a hardcoded table
- `#forge-status` reports cross-repo activity (REQs originating elsewhere that touch this repo)
- `#forge-sprint` delegates cross-repo mechanics to each `#forge-proceed`; one sprint still originates all REQs from the invoking repo
- `#forge-bugfix` supports cross-repo bugs via `repo:` or `touched_repos:` on the bug frontmatter

### Single-repo mode (default)

If no `config.yml` exists or it has only a single `repos:` entry, every prompt falls back to single-repo behavior. Existing projects are unaffected until they opt in by creating `config.yml`.

## Stack support

The toolkit's workflow is stack-agnostic. Prompts that need to do stack-specific things (deploy a Cloud Run service, push a build to an iOS device, etc.) read `.forge/config.yml` to learn what your stack is and what concrete values to use.

| Capability | Where the prompt checks | What you fill in |
|---|---|---|
| Deploy confirmation (`#forge-bugfix`, `#forge-wrapup`) | `stack.backends` includes `cloud-run` | `gcp.staging_project`, `gcp.production_project` |
| AKS deploy confirmation (`#forge-bugfix`, `#forge-wrapup`) | `stack.backends` includes `k8s` | `aks.cluster_name`, `aks.resource_group`, `services.<id>.namespace` |
| Canary deploys (`#forge-canary`) | `services:` block | service name, region, image path per repo (Cloud Run) |
| AKS canary / rollout verification (`#forge-canary`) | `stack.backends` includes `k8s` | `services.<id>.deployment_name`, `services.<id>.health_check_path` |
| iOS device deploys (`#forge-bugfix`, `#forge-wrapup`) | `stack.frontends` includes `ios` | `ios.deploy_targets`, `ios.deploy_command` |
| Convention checking (`#forge-review`, `#forge-reflect`) | `.forge/context/rules/conventions.rules.md` | declare your project's naming, logging, and API conventions |

If you want to add support for a new stack (e.g., AWS Lambda backends, Android device deploys), edit the relevant prompt to handle the new `stack.*` value and document it in [`templates/config-template.yml`](templates/config-template.yml). PRs welcome.

## Updating

Pull the latest toolkit and re-copy the `.github/` directory into each project repo:

```bash
cd /path/to/copilot-forge
git pull

# Then in each project repo:
cp -r /path/to/copilot-forge/.github .
```

Use `#forge-template-drift` in any project to check whether local `.forge/templates/` copies are out of date with the canonical `templates/` in this toolkit repo.

## Contributing

This is published as a generic toolkit you can fork or contribute back to. Patches that add presets, support new stacks, or sharpen workflows for stacks already supported are all welcome.

## FAQ

Got questions about token consumption, external LLMs, or documentation drift? Check out the [Frequently Asked Questions (FAQ)](FAQ.md).

