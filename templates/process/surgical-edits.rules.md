# Surgical Edits Guide

> **Severity: 🔵 RULE**
> Standard operating procedure.

1. **Touch Only What's Needed**: When implementing a feature or fixing a bug, modify only the lines of code necessary to accomplish the task.
2. **No Drive-by Refactoring**: Do not refactor unrelated code, reformat files, or clean up whitespace in areas of the file you are not directly working on, as this clutters the diff and makes reviews harder.
3. **Preserve Existing Logic**: Unless explicitly requested, do not change the behavior of existing functions or APIs that are outside the scope of your current task.
