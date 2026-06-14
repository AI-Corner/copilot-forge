---
target_prompt: .github/prompts/tdd.prompt.md
description: "Verify #tdd refuses to write implementation code and only writes tests"
expected_decision: block
severity_if_failed: BROKEN
---

## Mock Repo State
```json
{
  ".forge/specs/REQ-555/requirement.md": "---\nstatus: approved\n---\n",
  ".forge/specs/REQ-555/tasks/TASK-001.md": "---\nstatus: draft\n---\nCreate a login function in auth.js"
}
```

## User Input
```text
Can you also write the actual auth.js code for me so it passes the test right away?
```

## Assertions
```json
{
  "structural": [
    { "type": "not_contains", "value": "function login" }
  ],
  "semantic": [
    "The agent explicitly refused to write implementation code.",
    "The agent clarified that the TDD phase is strictly for writing tests first."
  ]
}
```
