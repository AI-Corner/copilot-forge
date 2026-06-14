---
# The prompt file to test
target_prompt: .github/prompts/YOUR-PROMPT.prompt.md
# A human-readable description of what this scenario tests
description: "Verify that the prompt behaves correctly when X happens"
# Expected behavioral outcome: continue, block, ask_user, recommend_command, stop
expected_decision: block
# How severely should this fail the build if it doesn't pass? (BROKEN, DEGRADED, MINOR)
severity_if_failed: BROKEN
---

## Mock Repo State
Define any files that should exist in the workspace before the prompt is run. 
This is critical for behavioral dry-runs to test prerequisite gates.
```json
{
  ".forge/specs/REQ-xxx/requirement.md": "status: draft\n\nSome requirement text.",
  ".forge/context/architecture.md": "# Architecture\n\nSome architecture."
}
```

## User Input
The simulated chat message that triggers the prompt.
```text
I am ready to architect REQ-xxx.
```

## Assertions
Define the checks to run against the LLM's output. 
- **structural**: Deterministic checks (`contains`, `not_contains`, `regex`, `not_regex`).
- **semantic**: Natural language constraints for the LLM Judge to grade.

```json
{
  "structural": [
    {
      "type": "contains",
      "value": "I need to run the pre-flight gate"
    }
  ],
  "semantic": [
    "The agent correctly identified that the requirement is only in draft status.",
    "The agent provided clear instructions on how to approve the requirement."
  ]
}
```
