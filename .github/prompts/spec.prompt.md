---
agent: agent
tools: [codebase, runCommand, changes]
description: Write a requirement spec from a feature request
---

# spec — Requirement Specification

You are writing a requirement spec following the spec-driven Copilot Forge process.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Feature request: [provided by the user in the chat message that invoked this prompt]

## Prerequisites

Before proceeding:
1. Use the codebase tool to verify `.forge/context/project-overview.md` exists. If it doesn't, stop and tell the user: "The `.forge/` structure hasn't been initialized. Run `#init` first."
2. Read `.forge/context/project-overview.md` for grounding context.
3. Read `.forge/templates/requirement-template.md` (or `templates/requirement-template.md` at the toolkit root).

## Instructions

### Step 1: Understand the Request
1. Read `.forge/context/project-overview.md` and `.forge/context/architecture.md` for grounding context.
2. Read `.forge/context/taxonomy.md` for tag vocabulary.
3. If the feature request is vague or ambiguous, ask clarifying questions before proceeding. Wait for answers.

### Step 1.5: Derive Query Tags for Retrieval
Before searching for prior context, derive a structured query from the feature request:
- **component** — narrow area this touches (e.g., `API/auth`, `iOS/SwiftUI`)
- **domain** — broader problem domain (e.g., `auth`, `payments`, `ui`)
- **stack** — tech layers implicated (e.g., `express`, `postgres`, `swiftui`)
- **concerns** — cross-cutting dimensions (e.g., `security`, `perf`, `a11y`)
- **tags** — free-form keywords from the feature description

Surface the proposed query to the user and wait for confirmation or edits before proceeding.

### Step 1.6: Retrieve Prior Context
Search for relevant prior artifacts using the codebase tool:
1. Scan `.forge/knowledge/lessons/*.md` — read frontmatter for `component`, `domain`, `tags`. Keep those matching the query.
2. Scan `.forge/specs/*/requirement.md` — include only where frontmatter `status` is `approved`, `in-progress`, or `deployed`.
3. Scan `.forge/bugs/*.md` — include only where frontmatter `status` is `resolved`.

Score each candidate:
- `+3` if `doc.component == query.component`
- `+2` if `doc.domain == query.domain`
- `+2 × overlapping concerns`
- `+1 × overlapping stack/tags`

Take the top 15 by score and read their full content. Surface a retrieval summary to the user before authoring.

### Step 2: Determine the Next REQ ID
1. Run in terminal: `cat .forge/.next-req 2>/dev/null || echo "1"`
2. Use the returned number as the REQ ID (zero-pad to 3 digits, e.g., REQ-001).
3. Write the incremented value back: `echo $((NUM + 1)) > .forge/.next-req`


### Step 3: Create the Requirement Spec
1. Create directory: `.forge/specs/REQ-xxx-feature-slug/`
2. Create `requirement.md` using `.forge/templates/requirement-template.md`.
3. Fill in all sections:
   - **Frontmatter**: `id`, `title`, `status` (`draft`), `deployable`, `created`, `updated`, plus the five query tags from Step 1.5: `component`, `domain`, `stack`, `concerns`, `tags`
   - **Description**: What the feature does and why — specific and grounded in project context
   - **System Model**: Entities, Events, Permissions
   - **Business Rules**: Testable constraints numbered BR-1, BR-2, etc.
   - **Acceptance Criteria**: Concrete, testable criteria as checkboxes
   - **External Dependencies**: New APIs, services, or libraries needed
   - **Assumptions**: Things assumed to be true that could affect design
   - **Open Questions**: Questions that need answers before implementation
   - **Out of Scope**: Items explicitly excluded to prevent scope creep
   - **Retrieved Context**: List every retrieved source from Step 1.6 in the form `ID (corpus, score): title`. If none retrieved, write: `No prior context retrieved.`
4. **Inline citations**: where a retrieved doc directly informed a Business Rule or Acceptance Criterion, add `(informed by BUG-012)` at the end of that line.

### Step 4: Present for Review
1. Display the full requirement spec to the user.
2. Highlight any assumptions or open questions that need input.
3. Remind the user to run `#validate` before advancing to `#architect`.

## Quality Checklist
- [ ] Acceptance criteria are specific and testable (not vague)
- [ ] Description explains the "why" not just the "what"
- [ ] Assumptions are explicitly stated
- [ ] Out of scope items prevent scope creep
- [ ] No implementation details leaked into the requirement (that's for architecture phase)
- [ ] Retrieved Context section present
