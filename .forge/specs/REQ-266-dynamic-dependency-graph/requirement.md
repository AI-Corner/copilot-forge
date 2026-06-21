---
id: REQ-266
title: Dynamic Dependency Graph Visualization
status: approved
created: 2026-06-21
updated: 2026-06-21
priority: high
---

# REQ-266: Dynamic Dependency Graph Visualization

## Description
Provide a clear, intent-based dependency graph for all Copilot Forge prompts and agents. This will allow users to visually explore the architecture of the forge itself, distinguishing between orchestrator skills and specialized agents, and understanding exact execution flows.

## Acceptance Criteria
- [x] AC1: Refactor all prompt and agent files to use explicit 5-category dependency blocks (Incoming/Outgoing Skill and Agent dependencies).
- [x] AC2: Update `generate-graph.ps1` to parse the new intent-based structures.
- [x] AC3: Generate a D3.js interactive frontend visualization at `docs/graph/index.html`.
- [x] AC4: Link the visualizer in the project documentation (README and Roadmap).
