---
target_prompt: .github/prompts/architect.prompt.md
description: "Verify #architect correctly blocks execution when the requirement status is missing or invalid"
expected_decision: block
severity_if_failed: BROKEN
---

## Mock Repo State
```json
{
  ".forge/specs/REQ-999/requirement.md": "# REQ-999\n\nNo status frontmatter here.\nJust a bad file.",
  ".forge/context/architecture.md": "mock",
  ".forge/context/conventions.md": "mock"
}
```

## User Input
```text
Please architect REQ-999 for me.
```

## Assertions
```json
{
  "structural": [
    { "type": "contains", "value": "status" }
  ],
  "semantic": [
    "The agent explicitly stated that it cannot proceed because the requirement file is missing a valid draft or approved status.",
    "The agent did not attempt to generate a task list or Mermaid diagram."
  ]
}
```
