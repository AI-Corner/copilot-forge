---
target_prompt: .github/prompts/validate.prompt.md
description: "Verify #validate blocks advancement if dependent tasks are not complete"
expected_decision: block
severity_if_failed: BROKEN
---

## Mock Repo State
```json
{
  ".forge/specs/REQ-123/requirement.md": "---\nstatus: approved\n---\n",
  ".forge/specs/REQ-123/tasks/TASK-001.md": "---\nstatus: complete\n---\n",
  ".forge/specs/REQ-123/tasks/TASK-002.md": "---\nstatus: draft\ndependencies: [TASK-001]\n---\n"
}
```

## User Input
```text
I am done with implementation, please validate my work.
```

## Assertions
```json
{
  "structural": [
    { "type": "contains", "value": "TASK-002" }
  ],
  "semantic": [
    "The agent explicitly identified that TASK-002 is still in draft status.",
    "The agent stated that validation cannot pass until all tasks are complete."
  ]
}
```
