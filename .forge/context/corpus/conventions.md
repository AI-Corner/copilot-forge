# Conventions — Copilot Forge

## Prompts are markdown, not code

Every prompt and agent checklist is a markdown file. No TypeScript, no Python, no package.json. Copilot interprets the markdown at invocation time. This matters:

- **No build step**: edits take effect immediately after the file is saved and Copilot reloads it
- **No test runner**: "tests" are dogfooding — invoke the prompt on a real REQ and verify it produces the expected artifacts
- **Linting is minimal**: markdown formatting and YAML frontmatter validity. Nothing else.

## File and directory naming

- Main prompts: `.github/prompts/<name>.prompt.md` — lowercase, hyphenated (`spec`, `bugfix`, `template-drift`)
- Agent checklists: `.github/prompts/agents/<name>.prompt.md` — lowercase, hyphenated
- Templates: `templates/<artifact>-template.md`
- Presets: `presets/<stack-slug>.yml`
- IDs: `REQ-xxx` (zero-padded to 3 digits), `TASK-yyy`, `BUG-zzz`, `LESSON-nnn` — always uppercase prefix, always 3 digits minimum
- Slugs: lowercase kebab-case, ≤6 words, no dates, no bare numbers

## Prompt frontmatter

Every main prompt file must begin with YAML frontmatter:

```yaml
---
mode: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: One-line summary of what this prompt does
---
```

`mode: agent` gives the prompt access to tools. `tools:` declares exactly which tools are available. Only include `terminalLastCommand` if the prompt needs to inspect prior terminal output. Agent checklists (`agents/`) typically only need `[codebase]`.

## Ethos reference pattern

Every main prompt begins with:

```markdown
> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
```

Never hardcode the ethos body inside a prompt — Copilot's global instruction file (`.github/copilot-instructions.md`) is loaded automatically for every session. The `>` blockquote is a visual callout, not a functional injection.

## Context loading pattern

Prompts load project context via the **codebase tool**, not bash macros. Example pattern:

```markdown
### Prerequisites
Use the codebase tool to verify `.forge/context/project-overview.md` exists.
Read `.forge/context/architecture.md` and `.forge/context/conventions.md` via the codebase tool.
```

Never use `!bash` macro syntax or `cat` commands for context loading. In Copilot, the `codebase` tool handles file reads.

## Prerequisites block

Every prompt that depends on the `.forge/` scaffold must have a `## Prerequisites` section that stops with a clear "run `#forge-init` first" message if required files are missing. Do not silently produce broken output when context is absent.

## Terminal commands in prompts

Use the `runCommand` tool (declared in frontmatter) for deterministic terminal operations:
- REQ/lesson counter reads: `cat .forge/.next-req 2>/dev/null || echo "1"`
- Counter writes: `echo $((NUM + 1)) > .forge/.next-req`
- Git operations: `git worktree add`, `git push`, `gh pr create`, etc.
- Test runs: `npm test`, `./gradlew test`, or equivalent

Keep terminal commands minimal — prefer the codebase tool for file reads, the `changes` tool for diffs, and the `runCommand` tool only for operations that genuinely require shell execution.

## Agent checklist pattern

Agent checklists in `.github/prompts/agents/` are **not invoked directly by users**. They are referenced inline by main prompts:

```markdown
**Step A — Self-Review** (reference: `#agents/reflector`):
Run the reflector checklist: ...
```

In Copilot, all agent checklists run **sequentially in the same context** — there is no parallel agent dispatch. The `#forge-proceed` and `#forge-review` prompts run 5–6 checklists one after another. Document this explicitly in any prompt that runs multiple checklists.

## Pipeline state

Prompts that span multiple phases (`#forge-proceed`) write a `pipeline-state.json` next to the REQ spec. This lets a long-running pipeline resume from interruption without replaying phases. Every phase update writes the state file atomically.

## Frontmatter conventions (artifact files)

All artifact types (requirements, tasks, bugs, lessons, assumptions) use YAML frontmatter:
- Dates: ISO format (`YYYY-MM-DD`)
- Arrays: JSON inline syntax (`tags: [a, b, c]`)
- Status enum values: lowercase strings (`draft`, `approved`, `in-progress`, `complete`)
- Required fields vary per template — `id`, `title`, `status`, `created` are always required

When adding new fields to templates, prefer additive — do not rename existing fields without a migration plan.

## Commits and branches

- Branch naming: `feat/REQ-xxx-short-description` for features, `fix/bug-xxx-short-description` for bugs
- Commit message format: `<type>(<scope>): <description> [TASK-xxx]` — types are `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- The TASK-xxx (or REQ-xxx) trailer is required for work tracked through the pipeline

## What NOT to do

- **Don't use `!bash` macros or `cat` commands for context**: use the `codebase` tool instead — this is the Copilot-native pattern.
- **Don't reference global install paths**: all paths are relative to the workspace or the toolkit repo root.
- **Don't dispatch parallel subagents**: Copilot runs sequentially. Document sequential execution explicitly where the original design assumed parallelism.
- **Don't create new prompts casually**: each new prompt is a commitment to maintain. Prefer extending an existing prompt unless the new responsibility is genuinely orthogonal.
- **Don't bypass ethos**: the six principles (especially #4 Verify, Don't Trust and #5 Process Is Not Optional) exist because shortcuts silently fail. If you're tempted to skip a validation gate, surface the tension to the user instead.
- **Don't hardcode project-specific paths**: prompts must work for any consumer project, not just a specific one.
- **Don't edit `templates/` without considering downstream**: consumer projects that ran `#forge-init` got a copy of the templates. Template changes propagate via `#forge-template-drift` detection, not auto-update.

## Testing changes

Because this is a copy-based install, there is no staging layer. To validate a prompt change:

1. Save the change in this toolkit repo
2. Open a Copilot Chat session in a consumer project (one that has `.github/` copied from this toolkit)
3. Invoke the changed prompt on a real or synthetic REQ
4. Verify the artifacts it produces match the intended behavior
5. If broken, fix here and re-copy `.github/` to the consumer project

The toolkit's own `#forge-proceed REQ-xxx` pipeline can also exercise changes end-to-end.
