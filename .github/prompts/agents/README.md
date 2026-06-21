# Copilot Forge Agents

This directory contains the autonomous agents and sensors used by the Copilot Forge pipeline.

## Sensor Split

To optimize token usage and prevent the AI from reviewing broken code, sensors are strictly divided into two categories:

### 1. `computational/`
These are fast, deterministic shell commands that yield binary PASS/FAIL results (e.g., linters, compilers, test runners, secret scanners). 
**Rule**: Computational sensors must always run *first*. If any computational sensor fails, the pipeline must stop and allow the developer to fix the issue.

### 2. `inferential/`
These are LLM-based heuristics and reviewers (e.g., code quality reviews, architecture reviews, spec adherence). 
**Rule**: Inferential sensors should *only* run after all computational sensors have passed. Spending tokens to have an LLM review code that doesn't even compile is a waste of resources.

## Other Agents
Agents in the root of this directory (e.g., `task-implementer`, `architecture-mapper`) are implementation or planning agents that are not part of the strict verification loop.
