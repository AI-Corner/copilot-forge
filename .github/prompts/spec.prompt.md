---
agent: agent
tools: [codebase, runCommand, changes]
description: Write a requirement spec from a feature request
---

# spec — Requirement Specification

You are writing a requirement spec following the spec-driven Copilot Forge process.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.
> **Focus**: Act as the product manager. Only use `.forge/context/*.md` and the initial feature request; ignore any earlier chat history or brainstorming.

## Input

Feature request: [provided by the user in the chat message that invoked this prompt]

## Prerequisites

Before proceeding:
1. Use the codebase tool to verify `.forge/context/project-overview.md` exists. If it doesn't, stop and tell the user: "The `.forge/` structure hasn't been initialized. Run `#init` first."
2. Read `.forge/context/project-overview.md` for grounding context.
3. Read `.forge/templates/requirement-template.md` (or `templates/requirement-template.md` at the toolkit root).

## Instructions

> **Strict Rule**: Keep the requirement document strictly concise. Use short bullet points. Do not invent filler, irrelevant edge cases, or hallucinate implementation details. DO NOT generate QA, Support, or Architecture documents — those are handled in later phases.

### Step 1: Workflow Routing (VIBE vs SDD)

Evaluate the feature request to decide whether it should be processed as "VIBE" (fast, vibe coding, no heavy documentation) or "SDD" (full Software Design & Development workflow).

1. Answer "YES" to any of the following if true:
   a) Cross-boundary impact: touches multiple architecture layers or multiple repos.
   b) State/DB change: modifies schema, writes migrations, or alters persistent state.
   c) Security/Auth impact: modifies auth flows, RBAC, or exposes new public APIs.
   d) Infrastructure/Dependencies: provisions new cloud resources or adds major external libraries.
   e) Hard to test/rollback: correctness is hard to validate locally or rollback is difficult.
   f) Ambiguity: requirement is unclear, vague, or likely to evolve significantly.
   g) Unit Tests Required: The logic is complex enough that new unit or integration tests must be written to prove it works.

2. Decision:
   - If ANY of the above is YES → Proceed with SDD (go to Step 1.1).
   - If ALL are NO → The requirement is suitable for VIBE. Stop immediately and ask the user: *"This looks like a small, isolated change suitable for Vibe Coding. Would you like to use the lightweight `#vibe` workflow instead? If yes, please run `#vibe [your requirement]`."* Do not proceed further until the user decides.

### Step 1.1: Understand the Request
1. Read `.forge/context/project-overview.md` and `.forge/context/architecture.md` for grounding context.
2. Read `.forge/context/taxonomy.md` for tag vocabulary.
3. If the feature request is vague or missing key dimensions, act as an "Architectural Interviewer". Ask clarifying questions specifically mapping to the Zachman 5W1H Framework:
   - **WHAT**: Are the data structures and API boundaries clear?
   - **WHO**: Who are the actors? What are the RBAC/security perimeters?
   - **WHEN**: What triggers the action?
   - **WHERE**: Are there specific infrastructure or network constraints?
   - **WHY**: What are the unbreakable business rules or compliance invariants?
   - **HOW**: Does this deviate from the standard stack?
   Wait for answers before proceeding.

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

Take the top 5 by score and read their full content. Surface a retrieval summary to the user before authoring.

### Step 2: Determine the Next REQ ID
1. Run in terminal: `cat .forge/.next-req 2>/dev/null || echo "1"`
2. Use the returned number as the REQ ID (zero-pad to 3 digits, e.g., REQ-001).
3. Write the incremented value back: `echo $((NUM + 1)) > .forge/.next-req`


### Step 3: Create the Requirement Spec
1. Create directory: `.forge/specs/REQ-xxx-feature-slug/`
2. Create `requirement.md` using `.forge/templates/requirement-template.md`.
3. Fill in all sections:
   - **Frontmatter**: `id`, `title`, `status` (`draft`), `deployable`, `created`, `updated`, plus the five query tags from Step 1.5: `component`, `domain`, `stack`, `concerns`, `tags`
   - **1. WHAT (System Capabilities & Data)**: Exact data structures and API boundaries
   - **2. WHO (Identity & Access)**: Actors, roles, and security perimeters
   - **3. WHEN (Event Flows & Triggers)**: Triggers and event flows
   - **4. WHERE (Infrastructure & Environment)**: Deployment boundaries and networks
   - **5. WHY (Business Rules & Invariants)**: Testable constraints numbered BR-1, BR-2, etc.
   - **6. HOW (Implementation & Tech Stack)**: Tech stack and architectural patterns
   - **Acceptance Criteria**: Concrete, testable criteria as checkboxes
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
