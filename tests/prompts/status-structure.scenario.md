---
target_prompt: .github/prompts/status.prompt.md
description: "Verify #status emits the correct required sections for a healthy pipeline"
expected_decision: continue
severity_if_failed: DEGRADED
---

## Mock Repo State
```json
{
  ".forge/specs/REQ-111/requirement.md": "---\nstatus: approved\n---\n",
  ".forge/specs/REQ-111/tasks/TASK-001.md": "---\nstatus: complete\n---\n",
  ".forge/specs/REQ-111/pipeline-state.json": "{\"currentPhase\": 4, \"completedPhases\": [1,2,3]}"
}
```

## User Input
```text
What is the status of the project?
```

## Assertions
```json
{
  "structural": [
    { "type": "contains", "value": "REQ-111" },
    { "type": "contains", "value": "TASK-001" }
  ],
  "semantic": [
    "The agent output a clear status report.",
    "The agent identified the current pipeline phase accurately."
  ]
}
```
