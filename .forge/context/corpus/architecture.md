# Architecture — Copilot Forge

## Top-level layout

```
copilot-forge/
├── ETHOS.md                         # 6 principles — referenced by every prompt session
├── README.md                        # Install + prompt catalog
├── .github/
│   ├── copilot-instructions.md      # Global Copilot ethos (auto-loaded by Copilot for every session)
│   └── prompts/
│       ├── *.prompt.md              # Main prompts (spec, architect, proceed, etc.)
│       └── agents/
│           └── *.prompt.md          # Agent checklists (referenced inline by main prompts)
├── .vscode/
│   └── settings.json                # Enables Copilot instruction files and prompt files
├── templates/
│   └── *.md / *.yml / *.json        # Canonical templates (copied into consumer projects by #forge-init)
├── presets/
│   └── *.yml                        # Stack-shaped starter configs for .forge/config.yml
└── .forge/                          # Minimal self-tracking for toolkit-internal REQs
    ├── context/                     # This directory — project-overview, architecture, conventions
    └── specs/REQ-xxx-*/             # Requirement specs for toolkit changes
```

## Prompt anatomy

Every main prompt is a single markdown file at `.github/prompts/<name>.prompt.md` with this shape:

1. **YAML frontmatter**: `mode: agent`, `tools: [codebase, runCommand, ...]`, `description`
2. **Title + one-line framing** — what the prompt does
3. **Ethos reference**: `> Follow the principles in .github/copilot-instructions.md`
4. **Input**: how the prompt reads user arguments from the chat message
5. **Prerequisites**: blocking checks (e.g., "verify `.forge/context/project-overview.md` exists")
6. **Instructions**: numbered steps, often with sub-steps and inline terminal commands via `runCommand`
7. **Quality checklist**: post-run self-check items

Prompts are pure markdown — no code, no package dependencies. Copilot loads them at invocation time and executes the instructions in-context.

## Agent checklist anatomy

Agent checklists live in `.github/prompts/agents/<name>.prompt.md`. They are **not invoked directly** by the user — they are referenced inline by main prompts like `#forge-review`, `#forge-reflect`, `#forge-analyze`, and `#forge-architect`.

Each checklist contains:
- A **role declaration** (what dimension this agent covers)
- A **focused checklist** (specific items to verify)
- A **reporting format** (how to surface findings)

The `#forge-proceed` and `#forge-review` prompts reference all review checklists sequentially.

## Template anatomy

Templates at `templates/*.md` are the canonical shape for each artifact type:

- `requirement-template.md` — REQ specs (id, title, status, deployable, dates; Description, System Model, Business Rules, Acceptance Criteria, etc.)
- `task-template.md` — implementation tasks (id, title, req, status, dependencies)
- `bug-template.md` — bug reports (id, title, status, severity, dates; Description, Reproduction, Root Cause, Resolution)
- `lesson-template.md` — lessons learned (id, title, domain, component, tags, req, created)
- `assumption-template.md` — validated-assumption knowledge entries
- `taxonomy-template.md` — tag vocabulary for retrieval scoring
- `config-template.yml` — annotated `.forge/config.yml` template

Templates are copied into consumer projects by `#forge-init` (into `.forge/templates/`). Consumer projects may customize their local copies; `#forge-template-drift` detects divergence from the canonical set.

## Copilot Forge pipeline shape (consumer-project view)

When a consumer project runs `#forge-proceed REQ-xxx`, the pipeline phases are:

```
Step 0: Preflight + create worktree + load shared context
   ↓
Phase 1: #forge-validate (spec)
   ↓
Phase 2: #forge-architect  ← creates .forge/specs/REQ-xxx/tasks/TASK-yyy.md
   ↓
Phase 3: #forge-validate (architecture + tasks)
   ↓
Phase 4: Implement (tasks executed sequentially in dependency order)
   ↓
Phase 5: Verify (reflector + 5 reviewer checklists run sequentially)
   ↓
Phase 6: Create PR (gh pr create)
   ↓
Phase 7: PR cleanup + CI checks
   ↓
Phase 7.5: #forge-canary (optional, if deployable: true)
   ↓
Phase 8: #forge-wrapup (merge, artifact updates, knowledge capture, deploy)
```

Each phase has a validation gate. Failed validation loops up to 3 times before pausing for human input. Pipeline state is persisted in `pipeline-state.json` so a session can resume from interruption.

## Knowledge retrieval

Prompts retrieve relevant prior knowledge at context-loading time via a **weighted-score retriever** over `.forge/knowledge/`:

- **Lessons** (`.forge/knowledge/lessons/*.md`) — surfaced by `#forge-spec`, `#forge-architect`, `#forge-reflect`, `#forge-review`
- **Specs** (`.forge/specs/*/requirement.md`) — surfaced by `#forge-spec` for related prior requirements
- **Bugs** (`.forge/bugs/*.md`) — surfaced by `#forge-spec` for related resolved bugs

Scoring: `+3` component match, `+2` domain match, `+2×` overlapping concerns, `+1×` overlapping tags. Top 15 by score are read in full.

## Key cross-cutting behaviors

- **Worktree isolation**: `#forge-proceed` creates a git worktree per REQ at `.worktrees/REQ-xxx` so the feature branch stays isolated from the main workspace during implementation.
- **Per-repo REQ counter**: each consumer repo maintains its own `.forge/.next-req` counter — no global shared state.
- **Cross-repo coordination**: optional `repos:` block in `.forge/config.yml` enables multi-repo REQs. Tasks carry a `repo:` frontmatter field; `#forge-proceed` creates worktrees and opens PRs in each touched repo.
- **Pipeline state**: `pipeline-state.json` next to each REQ spec allows `#forge-proceed` to resume a pipeline after interruption without replaying completed phases.
- **Copy-based updates**: toolkit changes propagate to consumer projects by re-copying `.github/` — use `#forge-template-drift` to detect stale local template copies.
