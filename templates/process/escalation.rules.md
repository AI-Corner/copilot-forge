# Escalation Guide

> **Severity: 🟡 GOLDEN PATH**
> Deviations from these rules require explicit justification in your reasoning.

1. **Don't Loop Endlessly**: If you have attempted to fix a failing test or a compilation error 3 times without success, stop trying. Do not continue to apply random changes hoping one will work.
2. **Escalate to User**: When you are stuck, escalate the issue to the user. Provide a clear summary of what is failing, what you have already tried, and what you suspect the root cause might be.
3. **Preserve State**: When escalating, ensure the codebase is left in a readable state. Do not leave half-finished, syntactically invalid code if you can avoid it.
