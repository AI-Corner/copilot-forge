---
id: SUP-002
title: "Support: End-to-End Pipeline (#forge-proceed)"
related_req: core-feature
created: 2026-05-04
updated: 2026-05-04
component: "proceed"
domain: "workflow"
tags: ["proceed", "pipeline", "workflow", "end-to-end"]
---

## 1. Feature Overview
The `#forge-proceed` prompt runs the entire Spec-Driven Development pipeline sequentially: validation, architecture, TDD, implementation, reflection, review, and wrap-up.

## 2. Common User Queries & FAQ
- **Q: Can I resume `#forge-proceed` if it fails halfway?**
  **A:** Yes. The pipeline state is saved in `pipeline-state.json`. Simply run `#forge-proceed REQ-xxx` again, and it will resume from the last uncompleted phase.
- **Q: What personas are called when I type `#forge-proceed` and where is this defined?**
  **A:** `#forge-proceed` is a master orchestrator that triggers a phased pipeline. It doesn't call personas immediately. Instead, during Phase 5 (Review), the `proceed.prompt.md` file explicitly instructs Copilot to run through a gauntlet of review checklists sequentially. It reads the files in `.github/prompts/agents/` (such as `security-auditor.md` and `architecture-reviewer.md`), applies each checklist to the code, and consolidates the findings.

## 3. Troubleshooting & Expected Behavior
| Scenario / Symptom | Expected Behavior | Workaround / Fix |
|-------------------|-------------------|------------------|
| The pipeline stops with a Critical finding. | `#forge-proceed` halts if `#forge-review` or `#forge-validate` finds a critical error. | Fix the error manually, or ask Copilot to fix it, then re-run `#forge-proceed`. |
| PR is not created. | `#forge-wrapup` creates a PR via GitHub CLI. | Ensure you are authenticated with `gh auth login` and have a clean working tree. |

## 4. Known Limitations
- Copilot has no multi-agent parallelism, so `#forge-proceed` runs everything sequentially.
