# Scoping Guide

> **Severity: 🔵 RULE**
> Standard operating procedure.

1. **One Concern Per Task**: Break down work into single, cohesive tasks. A single task should ideally not span across the database, backend, and frontend simultaneously if it can be avoided.
2. **Commit Size**: Aim to keep commits under 500 lines of changes. If a change is getting massive, consider if it can be broken down into smaller, logical commits.
3. **Avoid Scope Creep**: Do not implement features or "nice to haves" that were not explicitly requested in the acceptance criteria.
