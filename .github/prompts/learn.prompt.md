---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Add a knowledge document (lesson, assumption, ADR, support, or QA guide) to .forge/knowledge/
---

# learn — Standalone Knowledge Capture

You are adding a new knowledge document to this project's `.forge/knowledge/` directory. This prompt lets you capture knowledge **at any time** — you do not need an active REQ, pipeline, or `#wrapup` session.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Knowledge to capture: [provided by the user — free text, attached files, URLs, or a reference to existing codebase files]

## Instructions

### Step 1: Verify Forge Structure

1. Use the codebase tool to confirm `.forge/knowledge/` exists with subdirectories: `assumptions/`, `lessons/`, `support/`, `decisions/`, `qa/`.
2. If any are missing, create them (with `.gitkeep` files).
3. Ensure the corresponding templates exist in `.forge/templates/` (fall back to `templates/` at the toolkit repo root).

### Step 2: Classify Knowledge Type

Determine the type from user input or ask if ambiguous:

| Type | Use When | Template | Directory | ID Prefix |
|------|----------|----------|-----------|-----------|
| **lesson** | A takeaway from experience — something to do or avoid in the future | `lesson-template.md` | `lessons/` | `LESSON` |
| **assumption** | A belief being recorded for tracking — validated, invalidated, or unresolved | `assumption-template.md` | `assumptions/` | `ASSUME` |
| **adr** | An architectural or technical decision with rationale and consequences | `adr-template.md` | `decisions/` | `ADR` |
| **support** | User-facing documentation, FAQ, or troubleshooting guide | `support-template.md` | `support/` | `SUP` |
| **qa** | A manual test guide with step-by-step verification procedures | `manual-qa-template.md` | `qa/` | `QA` |

**Classification heuristic** (apply when the user didn't specify a type):
- Mentions "we learned", "next time", "mistake", "surprise", "gotcha" → **lesson**
- Mentions "we assume", "hypothesis", "unverified", "need to confirm" → **assumption**
- Mentions "we decided", "tradeoff", "alternative", "why we chose" → **adr**
- Mentions "how to use", "FAQ", "troubleshooting", "user guide" → **support**
- Mentions "test steps", "verify", "manual QA", "expected result" → **qa**
- If still ambiguous, ask the user: "What type of knowledge is this? (lesson / assumption / adr / support / qa)"

### Step 3: Mint ID and Filename

1. Determine the next ID using the atomic counter at `.forge/.next-<type>` (e.g., `.forge/.next-lesson`):
   ```bash
   ID_NUM=$(cat .forge/.next-lesson 2>/dev/null || echo "1")
   echo $((ID_NUM + 1)) > .forge/.next-lesson
   ```
   Replace `lesson` with the appropriate type: `lesson`, `assume`, `adr`, `sup`, `qa`.

2. Zero-pad the ID to 3 digits.

3. Generate a slug: lowercase kebab-case, ≤ 6 words, descriptive of the content.

4. Compose the filename: `<PREFIX>-<padded-id>-<slug>.md`
   Examples: `LESSON-005-signed-url-ttl-mismatch.md`, `ADR-003-use-graphql-for-public-api.md`

### Step 4: Extract and Structure Content

Read the user's input (free text, attached files, or codebase references). Transform it into the selected template's structure:

#### For Lessons (`lesson-template.md`)
- **Frontmatter**: Populate `id`, `title`, `component`, `domain`, `stack`, `concerns`, `tags`, `created`, `updated`. Set `req` to `N/A` if not tied to a REQ.
- **What Happened**: Summarize the situation.
- **Lesson**: State the key takeaway.
- **Why It Matters**: Describe impact if ignored.
- **Applies When**: Conditions for relevance.

#### For Assumptions (`assumption-template.md`)
- **Frontmatter**: Populate `id`, `title`, `status` (default `unresolved`), `created`. Set `req` to `N/A` if not tied to a REQ.
- **Assumption**: What is assumed true.
- **Context**: Why it was made and what depends on it.
- **Resolution**: Leave blank if unresolved, or fill if the user provides resolution info.

#### For ADRs (`adr-template.md`)
- **Frontmatter**: Populate `id`, `title`, `status` (default `proposed`), `component`, `domain`, `stack`, `concerns`, `created`, `updated`. Set `req` to `N/A` if not tied to a REQ.
- **Context**: The problem or forces at play.
- **Decision**: What was decided.
- **Rationale**: Why this choice.
- **Consequences**: Positive and negative downstream effects.

#### For Support Docs (`support-template.md`)
- **Frontmatter**: Populate `id`, `title`, `component`, `domain`, `tags`, `created`, `updated`. Set `related_req` to `N/A` if not tied to a REQ.
- **Feature Overview**: User-friendly explanation.
- **Common User Queries & FAQ**: Extract Q&A pairs.
- **Troubleshooting & Expected Behavior**: Table of scenarios.
- **Known Limitations**: Edge cases or constraints.

#### For QA Guides (`manual-qa-template.md`)
- Fill in Objective, Prerequisites, Test Steps table, Verification Commands, and Edge Cases.

### Step 5: Tag Using Taxonomy

1. Read `.forge/context/taxonomy.md` to learn the project's vocabulary for `component`, `domain`, `stack`, `concerns`.
2. Select the most appropriate values from the taxonomy. If the content introduces a genuinely new area not in the taxonomy, use a reasonable value and suggest the user add it to `taxonomy.md`.
3. Add 2-5 free-form `tags` keywords that describe the content.

### Step 6: Write the Document

1. Save the document to `.forge/knowledge/<type-dir>/<filename>.md`.
2. If an `_index.md` exists in that directory, append a link to the new document.
3. If no `_index.md` exists and there are now 3+ documents in the directory, create one with links to all existing documents.

### Step 7: Summary

Present the user with:
```
## Knowledge Captured

- **Type**: <type>
- **ID**: <PREFIX-xxx>
- **File**: `.forge/knowledge/<type-dir>/<filename>.md`
- **Tags**: component=<val>, domain=<val>, stack=[<vals>], concerns=[<vals>], tags=[<vals>]

<one-line summary of the knowledge captured>
```

Suggest follow-up if relevant:
- "This lesson may affect existing architecture — consider running `#analyze` to check for drift."
- "This ADR introduces a new standard — consider updating `.forge/context/architecture.md`."
- "This assumption is unresolved — revisit after implementation to validate or invalidate."
