# Self-Validation Guide

> **Severity: 🟡 GOLDEN PATH**
> Deviations from these rules require explicit justification in your reasoning.

1. **Independent Evidence**: When verifying that a task is complete, you cannot use your own previous output as evidence. "I just wrote the code, so it works" is not valid.
2. **Deterministic Checks**: You must rely on external, deterministic feedback—such as the output of a test runner, a linter, a compiler, or a successful API response—to validate your work.
3. **Double-Check Assumptions**: If a command succeeds silently (e.g., exit code 0 but no output), verify the side-effects (e.g., check that the file was actually modified) rather than assuming it did what you wanted.
