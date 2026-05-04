---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Generate a failing test suite based on the requirement spec before implementation (TDD)
---

# tdd — Test-Driven Development Phase

You are a Test-Driven Development (TDD) practitioner. Given a requirement ID (REQ-xxx) and its validated architecture, your goal is to write a comprehensive suite of failing tests *before* any implementation code is written.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md`. Tests must define the "what" and "how it fails", ensuring the red-green-refactor cycle is strictly adhered to.

## Input

REQ-xxx

## Instructions

### Step 1: Locate Context
1. Read `.forge/specs/REQ-xxx-*/requirement.md`.
2. Read the tasks and architecture generated in the `.forge/specs/REQ-xxx-*/tasks/` directory.
3. Use the `codebase` tool to inspect existing test infrastructure (e.g., JUnit/Mockito for Spring Boot, Jest/Vitest for React).

### Step 2: Identify Test Scenarios
Extract all acceptance criteria (ACs) and edge cases from the requirement spec and tasks. Plan out the unit and integration tests required.

### Step 3: Write Failing Tests (Red Phase)
1. Write the test files in the appropriate directories.
2. The tests must compile/parse correctly, but they MUST fail because the underlying business logic is not yet implemented (or throws `NotImplementedError` / `UnsupportedOperationException`).
3. Include unit tests for core logic and integration tests for API endpoints or database interactions.

### Step 4: Verify Failure
1. Use `runCommand` to execute the test suite (e.g., `mvn test` or `npm test`).
2. Verify that the tests actually run and fail as expected. This proves that the tests are executing and correctly asserting the absent behavior.

### Step 5: Output Report
Summarize the test suite created. List the tests that are currently failing, proving that the spec is covered. Report completion so the implementation phase can begin to make them pass (Green Phase).
