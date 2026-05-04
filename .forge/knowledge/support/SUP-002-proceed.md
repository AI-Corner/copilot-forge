---
id: SUP-002
title: "Support: End-to-End Pipeline (#proceed)"
related_req: core-feature
created: 2026-05-04
updated: 2026-05-04
component: "proceed"
domain: "workflow"
tags: ["proceed", "pipeline", "workflow", "end-to-end"]
---

## 1. Feature Overview
The `#proceed` prompt runs the entire Spec-Driven Development pipeline sequentially: validation, architecture, TDD, implementation, reflection, review, and wrap-up.

## 2. Common User Queries & FAQ
- **Q: Can I resume `#proceed` if it fails halfway?**
  **A:** Yes. The pipeline state is saved in `pipeline-state.json`. Simply run `#proceed REQ-xxx` again, and it will resume from the last uncompleted phase.

## 3. Troubleshooting & Expected Behavior
| Scenario / Symptom | Expected Behavior | Workaround / Fix |
|-------------------|-------------------|------------------|
| The pipeline stops with a Critical finding. | `#proceed` halts if `#review` or `#validate` finds a critical error. | Fix the error manually, or ask Copilot to fix it, then re-run `#proceed`. |
| PR is not created. | `#wrapup` creates a PR via GitHub CLI. | Ensure you are authenticated with `gh auth login` and have a clean working tree. |

## 4. Known Limitations
- Copilot has no multi-agent parallelism, so `#proceed` runs everything sequentially.
