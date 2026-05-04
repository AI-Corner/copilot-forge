---
agent: agent
tools: [codebase, runCommand, changes]
description: Design architecture and break a requirement into implementable tasks
---

# architect — Architecture & Task Breakdown

You are designing architecture and breaking a requirement into implementable tasks.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Requirement: [REQ-xxx ID or requirement description provided by the user]

## Prerequisites

Before proceeding, use the codebase tool to verify:
- `.forge/context/architecture.md` exists — stop and run `#init` if missing
- `.forge/context/conventions.md` exists — stop and run `#init` if missing

Read `.forge/templates/task-template.md` (or `templates/task-template.md` at the toolkit root).

## Instructions

### Step 1: Locate and Read the Requirement
1. If given a REQ ID, read `.forge/specs/REQ-xxx-*/requirement.md` via the codebase tool.
2. If given a description, search `.forge/specs/` for the matching requirement.
3. Verify the requirement status is `draft` or `approved` (not already `complete`).
4. Read `.forge/context/architecture.md` and `.forge/context/conventions.md` (skip if already in conversation).
5. Check `.forge/knowledge/assumptions/` for prior decisions that may affect design.
6. **Lessons — search first**: use the codebase tool to search `.forge/knowledge/lessons/` with patterns matching the affected area (e.g., `component:.*API/auth`). Read only matched files. Note applicable lessons in your architecture rationale.

### Step 2: Explore the Codebase
Use the codebase tool to explore systematically — run these explorations in sequence:

1. **Feature tracing** — search for similar existing implementations of this feature type. Look for similar API endpoints, service patterns, data models.
2. **Architecture mapping** — map all files and layers that will be affected. Use the codebase tool to trace imports and dependencies.
3. **Integration surfaces** — identify extension points, existing tests that will need updating, and API contracts this feature must respect.

Read the key files identified during exploration.

### Step 3: Design Architecture (if needed)
1. If the requirement involves new architectural decisions, create `.forge/specs/REQ-xxx-*/architecture.md`.
2. Document:
   - **Approach**: High-level design and rationale
   - **Data model changes**: New collections/fields, schema changes
   - **API changes**: New or modified endpoints
   - **Service layer**: New or modified services
   - **Key decisions**: ADRs with rationale (follow the style in `.forge/context/architecture.md`)
3. Propose any additions to `.forge/context/architecture.md` with rationale.

### Step 4: Break Into Tasks
1. Create `.forge/specs/REQ-xxx-*/tasks/` directory.
2. Determine the next TASK ID by scanning existing tasks across ALL specs.
3. **Detect repository mode**: check whether `.forge/config.yml` exists and declares a `repos:` block with more than one entry.
   - **Single-repo mode**: set `repo:` on each task to the primary repo id (or omit).
   - **Cross-repo mode**: every task MUST declare a `repo:` field. A single task should not modify files in multiple repos — split cross-repo work into separate tasks with explicit dependencies.
4. Create `TASK-xxx-description.md` for each task using `.forge/templates/task-template.md`.
5. Each task must specify:
   - **Frontmatter**: `id`, `title`, `status` (`draft`), `parent` REQ, `created`, `updated`, `dependencies`, `repo:` (required in cross-repo mode)
   - **Description**: What this task accomplishes
   - **Files to Create/Modify**: Specific file paths with descriptions
   - **Acceptance Criteria**: Concrete, testable criteria
   - **Technical Notes**: Implementation details, patterns to follow, edge cases
   - **Dependencies**: Other tasks that must complete first
6. Tasks must form a valid dependency graph (no cycles).
7. Order tasks so foundational work comes first (data layer → service → routes → UI).

### Step 5: Update Requirement Status
1. Update the requirement's frontmatter `status` from `draft` to `approved`.
2. Update the `updated` date.

### Step 6: Present for Review
1. Display the architecture decisions (if any).
2. Display the task breakdown as a dependency graph.
3. Summarize the implementation plan.
4. Remind the user to run `#validate` before starting implementation.

## Quality Checklist
- [ ] Architecture follows existing patterns (layered: routes → services → repositories)
- [ ] Tasks are small enough to implement in a single session
- [ ] Task dependencies form a valid DAG (no cycles), including cross-repo edges
- [ ] Every file to be modified is listed in at least one task
- [ ] Tests are included in task acceptance criteria
- [ ] No task has more than 3 dependencies
- [ ] In cross-repo mode: every task has a `repo:` field naming a valid repo id from `.forge/config.yml`
