# Copilot Forge Ethos

These principles guide every interaction in this repository. Follow them in all code generation, review, and development assistance tasks.

---

## 1. Spec First, Code Second

Never implement without a validated spec. The cheapest bug to fix is one caught in the spec. A 30-minute spec review prevents days of rework. If the requirement is ambiguous, stop and clarify — don't guess and ship.

**Applies when**: Starting any feature work, evaluating whether to skip ceremony, deciding how much planning is enough.

## 2. Knowledge Compounds

Every implementation must leave the codebase smarter. Lessons, assumptions, and architectural decisions are first-class artifacts, not afterthoughts. A lesson captured today prevents the same mistake across every future REQ.

**Applies when**: Wrapping up features, encountering surprising behavior, making non-obvious technical choices, validating or invalidating assumptions.

## 3. Parallel by Default

If tasks are independent, run them concurrently. Sequential execution is a choice that requires justification.

**Applies when**: Planning implementation order, launching task execution, running multiple REQs, deciding whether to batch or parallelize.

## 4. Verify, Don't Trust

LLM output is a draft, not a deliverable. Every phase has a validation gate. Every deploy has a canary. Every review has a second pass. Trust is earned through automated checks, not assumed from confidence.

**Applies when**: Completing any Copilot Forge phase, deploying code, reviewing AI-generated changes, merging PRs.

## 5. Process Is Not Optional

Prompt steps are a protocol, not a guideline. Execute every step literally — check every sub-bullet, verify every cleanup item. A "small" REQ does not earn a shortcut. If a step truly doesn't apply, say so explicitly rather than silently skipping it.

**Applies when**: Running any Copilot Forge prompt. Deciding whether a REQ is "too small" for full ceremony. Reaching a gate step and feeling tempted to hand-wave it.

## 6. If It's Broken, Fix It

When you hit a failure, fix the root cause — don't bypass it. Skipping hooks, swallowing exceptions, commenting out a flaky test, or working around a bug instead of fixing it are all forms of borrowing against future work at high interest.

**Applies when**: A test fails, a hook blocks a commit, a build error is "weird", an exception fires unexpectedly.

---

## Project Context

This repository contains the **Copilot Forge** — a spec-driven development framework. The `.forge/` directory in each project holds:
- `context/` — project-specific architecture, conventions, and overview
- `specs/` — requirement docs (REQ-xxx), architecture docs, and task files (TASK-xxx)
- `knowledge/` — assumptions validated, lessons learned
- `templates/` — local copies of document templates

When working in any project that uses Copilot Forge, always read `.forge/context/project-overview.md`, `.forge/context/architecture.md`, and `.forge/context/conventions.md` before making changes.

## How to Invoke Prompts

Use `#<prompt-name>` in Copilot Chat to invoke a prompt, e.g.:
- `#init` — bootstrap `.forge/` in a new project
- `#spec Add user login` — write a requirement spec
- `#proceed REQ-001` — run the full pipeline for a REQ
- `#status` — show current state of all Copilot Forge work
