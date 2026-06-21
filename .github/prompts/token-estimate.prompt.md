---

## Instructions

### Step 1: Measure Baseline Context (always loaded)

Use the `runCommand` tool to get file sizes in bytes for all files that are loaded at the start of every pipeline run:

```bash
# Get sizes of all baseline context files
Get-Item `
  ".github/copilot-instructions.md", `
  ".forge/context/project-overview.md", `
  ".forge/context/architecture.md", `
  ".forge/context/conventions.md", `
  ".forge/context/variables.md", `
  ".forge/context/taxonomy.md" `
  -ErrorAction SilentlyContinue | Select-Object Name, Length
```

Sum bytes â†’ divide by 4 â†’ **Baseline Context Tokens**.

### Step 2: Measure REQ-Specific Files (if REQ ID provided)

```bash
# Spec and tasks
Get-ChildItem ".forge/specs/REQ-xxx-*/" -Recurse -File | Select-Object Name, Length
```

Sum all `.md` and `.json` files under the REQ spec directory â†’ **REQ Artifact Tokens**.

### Step 3: Measure Prompt Files Loaded Per Phase

Run the following to measure each prompt file:

```bash
Get-Item `
  ".github/prompts/spec.prompt.md", `
  ".github/prompts/validate.prompt.md", `
  ".github/prompts/architect.prompt.md", `
  ".github/prompts/tdd.prompt.md", `
  ".github/prompts/proceed.prompt.md", `
  ".github/prompts/reflect.prompt.md", `
  ".github/prompts/review.prompt.md", `
  ".github/prompts/wrapup.prompt.md", `
  ".github/prompts/canary.prompt.md" `
  -ErrorAction SilentlyContinue | Select-Object Name, Length

# Agent checklists (loaded during Phase 5 review)
Get-ChildItem ".github/prompts/agents/" -File | Select-Object Name, Length
```

### Step 4: Measure Knowledge Retrieval (RAG) Files

The RAG system retrieves the top-scored lessons and support docs. Estimate conservatively by reading all lessons and support docs â€” the RAG system won't load all of them, but this gives you the worst-case ceiling.

```bash
Get-ChildItem ".forge/knowledge/" -Recurse -File | Select-Object Name, Length
```

### Step 5: Compute Phase Breakdown

Calculate estimated tokens for each pipeline phase based on what is loaded:

| Phase | Files Loaded |
|-------|-------------|
| **Step 0: Preflight** | Baseline context + requirement.md + config.yml |
| **Phase 1: Validate Spec** | validate.prompt.md + requirement.md |
| **Phase 2: Architect** | architect.prompt.md + baseline context + RAG lessons (top 5) |
| **Phase 3: Validate Architecture** | validate.prompt.md + architecture artifacts + tasks |
| **Phase 3.5: TDD** | tdd.prompt.md + requirement.md + tasks |
| **Phase 4: Implement** | proceed.prompt.md + all tasks + conventions.md (per task) |
| **Phase 5: Verify** | reflect.prompt.md + review.prompt.md + all 6 agent checklists + code diff |
| **Phase 6â€“7: PR + CI** | proceed.prompt.md sections only (minimal) |
| **Phase 7.5: Canary** | canary.prompt.md (if deployable) |
| **Phase 8: Wrapup** | wrapup.prompt.md + knowledge templates |

Produce the final table:

```
Phase                    | Est. Input Tokens | % of Total
-------------------------|-------------------|----------
Step 0: Preflight        |                   |
Phase 1: Validate Spec   |                   |
Phase 2: Architect       |                   |
Phase 3: Validate Arch   |                   |
Phase 3.5: TDD           |                   |
Phase 4: Implement       |                   |
Phase 5: Verify          |                   |
Phase 6-7: PR + CI       |                   |
Phase 8: Wrapup          |                   |
-------------------------|-------------------|----------
TOTAL (Input Tokens)     |                   | 100%
Est. Output Tokens       |                   | ~25% of input
Est. GRAND TOTAL         |                   |
```

### Step 6: Write Results to pipeline-state.json

If `pipeline-state.json` exists for this REQ, append the token estimate:

```json
"tokenEstimate": {
  "estimatedAt": "<ISO-timestamp>",
  "formula": "bytes / 4",
  "phases": {
    "preflight": <tokens>,
    "validate_spec": <tokens>,
    "architect": <tokens>,
    "validate_arch": <tokens>,
    "tdd": <tokens>,
    "implement": <tokens>,
    "verify": <tokens>,
    "pr_ci": <tokens>,
    "wrapup": <tokens>
  },
  "totalInputTokens": <tokens>,
  "estimatedOutputTokens": <tokens>,
  "estimatedGrandTotal": <tokens>,
  "note": "Approximation only (~4 chars/token). Actual Copilot usage may vary Â±20%."
}
```

### Step 7: Report Summary

Output the completed table and a one-line takeaway, e.g.:

```
Token Estimate for REQ-023 â€” My Feature Title
â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”
[table]

ðŸ’¡ Largest phase: Phase 5 (Verify) at ~X tokens â€” driven by 6 agent checklists + code diff.
ðŸ’¡ Total estimated session cost: ~X,XXX input tokens + ~X,XXX output tokens â‰ˆ X,XXX total.
---
agent: agent
tools: [codebase, runCommand]
description: Estimate token consumption for a Copilot Forge pipeline session by phase
---

# token-estimate â€” Session Token Usage Estimator

You are estimating the token footprint of a Copilot Forge pipeline run for a given REQ. Because GitHub Copilot does not expose live token counts, this prompt uses **character-to-token approximation** (~4 characters = 1 token for English/Markdown) to produce a phase-by-phase breakdown.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

> **Cost note**: Running this prompt inside Copilot Chat is itself a token-consuming operation (~1,000â€“2,000 tokens). For routine use, prefer the zero-cost alternative: run `token-estimate.ps1` directly from the terminal. Use this prompt only when the terminal script is unavailable.

## Input

Target: [REQ-xxx ID â€” provided by the user. If omitted, estimate baseline context only.]

## How Token Estimation Works

- **Formula**: `estimated_tokens = ceil(file_size_in_bytes / 4)`
- **Why 4?** OpenAI's tokenizer averages ~4 bytes per token for English prose and Markdown. Code is slightly denser (~3 bytes/token), but 4 is a safe conservative estimate.
- **Input vs. Output**: This estimate covers **input (context) tokens only**. Output tokens vary by task complexity. A rough multiplier: output â‰ˆ 20â€“35% of input for typical implementation tasks.
- **Accuracy**: Â±15â€“20%. Useful for relative comparisons between REQs, not for exact billing.

---

## Instructions

### Step 1: Measure Baseline Context (always loaded)

Use the `runCommand` tool to get file sizes in bytes for all files that are loaded at the start of every pipeline run:

```bash
# Get sizes of all baseline context files
Get-Item `
  ".github/copilot-instructions.md", `
  ".forge/context/project-overview.md", `
  ".forge/context/architecture.md", `
  ".forge/context/conventions.md", `
  ".forge/context/variables.md", `
  ".forge/context/taxonomy.md" `
  -ErrorAction SilentlyContinue | Select-Object Name, Length
```

Sum bytes â†’ divide by 4 â†’ **Baseline Context Tokens**.

### Step 2: Measure REQ-Specific Files (if REQ ID provided)

```bash
# Spec and tasks
Get-ChildItem ".forge/specs/REQ-xxx-*/" -Recurse -File | Select-Object Name, Length
```

Sum all `.md` and `.json` files under the REQ spec directory â†’ **REQ Artifact Tokens**.

### Step 3: Measure Prompt Files Loaded Per Phase

Run the following to measure each prompt file:

```bash
Get-Item `
  ".github/prompts/spec.prompt.md", `
  ".github/prompts/validate.prompt.md", `
  ".github/prompts/architect.prompt.md", `
  ".github/prompts/tdd.prompt.md", `
  ".github/prompts/proceed.prompt.md", `
  ".github/prompts/reflect.prompt.md", `
  ".github/prompts/review.prompt.md", `
  ".github/prompts/wrapup.prompt.md", `
  ".github/prompts/canary.prompt.md" `
  -ErrorAction SilentlyContinue | Select-Object Name, Length

# Agent checklists (loaded during Phase 5 review)
Get-ChildItem ".github/prompts/agents/" -File | Select-Object Name, Length
```

### Step 4: Measure Knowledge Retrieval (RAG) Files

The RAG system retrieves the top-scored lessons and support docs. Estimate conservatively by reading all lessons and support docs â€” the RAG system won't load all of them, but this gives you the worst-case ceiling.

```bash
Get-ChildItem ".forge/knowledge/" -Recurse -File | Select-Object Name, Length
```

### Step 5: Compute Phase Breakdown

Calculate estimated tokens for each pipeline phase based on what is loaded:

| Phase | Files Loaded |
|-------|-------------|
| **Step 0: Preflight** | Baseline context + requirement.md + config.yml |
| **Phase 1: Validate Spec** | validate.prompt.md + requirement.md |
| **Phase 2: Architect** | architect.prompt.md + baseline context + RAG lessons (top 5) |
| **Phase 3: Validate Architecture** | validate.prompt.md + architecture artifacts + tasks |
| **Phase 3.5: TDD** | tdd.prompt.md + requirement.md + tasks |
| **Phase 4: Implement** | proceed.prompt.md + all tasks + conventions.md (per task) |
| **Phase 5: Verify** | reflect.prompt.md + review.prompt.md + all 6 agent checklists + code diff |
| **Phase 6â€“7: PR + CI** | proceed.prompt.md sections only (minimal) |
| **Phase 7.5: Canary** | canary.prompt.md (if deployable) |
| **Phase 8: Wrapup** | wrapup.prompt.md + knowledge templates |

Produce the final table:

```
Phase                    | Est. Input Tokens | % of Total
-------------------------|-------------------|----------
Step 0: Preflight        |                   |
Phase 1: Validate Spec   |                   |
Phase 2: Architect       |                   |
Phase 3: Validate Arch   |                   |
Phase 3.5: TDD           |                   |
Phase 4: Implement       |                   |
Phase 5: Verify          |                   |
Phase 6-7: PR + CI       |                   |
Phase 8: Wrapup          |                   |
-------------------------|-------------------|----------
TOTAL (Input Tokens)     |                   | 100%
Est. Output Tokens       |                   | ~25% of input
Est. GRAND TOTAL         |                   |
```

### Step 6: Write Results to pipeline-state.json

If `pipeline-state.json` exists for this REQ, append the token estimate:

```json
"tokenEstimate": {
  "estimatedAt": "<ISO-timestamp>",
  "formula": "bytes / 4",
  "phases": {
    "preflight": <tokens>,
    "validate_spec": <tokens>,
    "architect": <tokens>,
    "validate_arch": <tokens>,
    "tdd": <tokens>,
    "implement": <tokens>,
    "verify": <tokens>,
    "pr_ci": <tokens>,
    "wrapup": <tokens>
  },
  "totalInputTokens": <tokens>,
  "estimatedOutputTokens": <tokens>,
  "estimatedGrandTotal": <tokens>,
  "note": "Approximation only (~4 chars/token). Actual Copilot usage may vary Â±20%."
}
```

### Step 7: Report Summary

Output the completed table and a one-line takeaway, e.g.:

```
Token Estimate for REQ-023 â€” My Feature Title
â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”
[table]

ðŸ’¡ Largest phase: Phase 5 (Verify) at ~X tokens â€” driven by 6 agent checklists + code diff.
ðŸ’¡ Total estimated session cost: ~X,XXX input tokens + ~X,XXX output tokens â‰ˆ X,XXX total.
ðŸ’¡ Results written to pipeline-state.json.
```

> **Note**: Run `token-estimate.ps1` from the terminal for a faster standalone estimate without needing a Copilot session.

## Internal Reference
- **Incoming Skill Dependencies**: *None*
- **Incoming Agent Dependencies**: *None*
- **Outgoing Skill Dependencies**: *None*
- **Outgoing Agent Dependencies**: *None*
- **Resource Dependencies**: `token-estimate.ps1`
