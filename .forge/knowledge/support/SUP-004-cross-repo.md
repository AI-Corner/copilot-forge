---
id: SUP-004
title: "Support: Cross-Repo Operations"
related_req: core-feature
created: 2026-05-04
updated: 2026-05-04
component: "config"
domain: "architecture"
tags: ["cross-repo", "config.yml", "multi-repo", "siblings"]
---

## 1. Feature Overview
Copilot Forge supports modifying multiple repositories simultaneously for a single feature by defining sibling repositories in `.forge/config.yml`.

## 2. Common User Queries & FAQ
- **Q: How does `#proceed` know which repos to touch?**
  **A:** It checks the `repo:` frontmatter on each task defined in the specification.

## 3. Troubleshooting & Expected Behavior
| Scenario / Symptom | Expected Behavior | Workaround / Fix |
|-------------------|-------------------|------------------|
| A task fails because the repo isn't found. | Cross-repo tasks require valid paths. | Ensure `.forge/config.yml` has the correct relative paths under the `repos:` block. |

## 4. Known Limitations
- All repositories must be open in the same VS Code Multi-Root Workspace or accessible via relative paths.
