# Convention Rules

These are the strict coding and formatting conventions for Copilot Forge. For full explanations, see `corpus/conventions.md`.

1. **Naming**:
   - Main prompts: `.github/prompts/<name>.prompt.md` (lowercase, hyphenated)
   - Agent checklists: `.github/prompts/agents/<name>.prompt.md`
   - IDs: `REQ-xxx`, `TASK-yyy`, `BUG-zzz`, `LESSON-nnn` (uppercase, 3 digits zero-padded)
2. **Frontmatter**: Every prompt MUST have YAML frontmatter declaring `mode: agent`, `tools: [...]`, and a `description`.
3. **Ethos**: Every main prompt MUST begin with `> **Ethos**: Follow the principles in .github/copilot-instructions.md throughout this session.`
4. **Context Loading**: Prompts MUST load context using the `codebase` tool, NEVER via `!bash` macros or `cat`.
5. **Prerequisites**: Prompts depending on `.forge/` MUST have a prerequisites check that stops and prompts the user to run `#forge-init` if files are missing.
6. **Sequential Agents**: Agent checklists MUST run sequentially. DO NOT dispatch parallel subagents.
7. **Commit Formatting**: Branch names: `feat/REQ-xxx...` or `fix/bug-xxx...`. Commits: `<type>(<scope>): <description> [TASK-xxx]`.
8. **What NOT to do**:
   - Do NOT use `!bash` or `cat` for reading files.
   - Do NOT reference global install paths.
   - Do NOT hardcode project-specific paths.
   - Do NOT bypass the ethos principles.
