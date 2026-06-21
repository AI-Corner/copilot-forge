# Subagent Trust Guide

> **Severity: 🔵 RULE**
> Standard operating procedure.

1. **Verify Subagent Output**: If you delegate work to a subagent (e.g., a test-writer agent or a refactoring agent), do not blindly trust that it completed the work correctly.
2. **Read the Diff**: Always run `git diff` to review the actual file changes made by the subagent before committing them or proceeding to the next step.
3. **Validate Tests**: If a subagent wrote tests, run them yourself to verify they pass and test the right things.
