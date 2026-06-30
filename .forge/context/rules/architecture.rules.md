# Architecture Rules

These are the strict architectural rules for Copilot Forge. For full explanations, see `corpus/architecture.md`.

1. **Prompt Anatomy**: Every main prompt MUST be a single markdown file at `.github/prompts/<name>.prompt.md`. It MUST include YAML frontmatter, an Ethos reference, Input, Prerequisites, Instructions, and a Quality checklist.
2. **Agent Checklists**: Checklists (`.github/prompts/agents/*.prompt.md`) are NEVER invoked directly by the user. They are referenced inline by main prompts and run sequentially.
3. **No Code in Prompts**: Prompts are pure markdown. No executable code or package dependencies are allowed.
4. **Worktree Isolation**: `#forge-proceed` MUST create an isolated git worktree per REQ at `.worktrees/REQ-xxx`.
5. **No Global State**: Each consumer repo maintains its own `.forge/.next-req` counter.
6. **Pipeline Resumption**: Prompts that span multiple phases MUST persist state in `pipeline-state.json` next to the REQ spec.
