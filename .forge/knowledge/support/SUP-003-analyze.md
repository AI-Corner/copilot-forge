---
id: SUP-003
title: "Support: Incremental Analysis (#forge-analyze)"
related_req: core-feature
created: 2026-05-04
updated: 2026-05-04
component: "analyze"
domain: "drift-resolution"
tags: ["analyze", "drift", "sync", "incremental"]
---

## 1. Feature Overview
`#forge-analyze` fixes documentation drift. It uses a stored git commit hash to find files changed since the last run, auditing only those files to update `architecture.md` and `conventions.md`.

## 2. Common User Queries & FAQ
- **Q: Does `#forge-analyze` scan my entire codebase?**
  **A:** No, it uses `git diff` against `.forge/.last-analyzed-commit` to only scan what changed.

## 3. Troubleshooting & Expected Behavior
| Scenario / Symptom | Expected Behavior | Workaround / Fix |
|-------------------|-------------------|------------------|
| `#forge-analyze` says "No changes found". | It should only run if there are diffs. | Ensure you have committed your manual changes, as it compares against the last recorded commit. |

## 4. Known Limitations
- It requires Git to be installed and initialized in the repository.
