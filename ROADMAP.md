# Copilot Forge — Roadmap & Future Enhancements

This document outlines strategic improvements to the Copilot Forge toolkit to further optimize Spec-Driven Development (SDD) for enterprise use, particularly for robust multi-service architectures (like Java Spring Boot + React + PostgreSQL + AKS).

---

## 1. Test-Driven Development (TDD) First Prompts

Currently, the pipeline follows: `Spec → Architect → Implement → Review`. This improvement introduces a `#tdd` phase right after `#architect`. The AI generates a suite of failing unit/integration tests before writing any production code, enforcing the "red-green-refactor" cycle.

*   **Complexity**: **Low**
*   **Benefit**: **High**
*   **Impact**: Guarantees that code implemented by the AI actually satisfies the specification's acceptance criteria in a verifiable way, significantly reducing bugs found in the `#review` stage.

## 2. Interactive Architecture Diagrams (Mermaid.js)

The `#architect` prompt currently outputs raw text/markdown for the system design. This upgrade forces the `#architect` prompt to consistently output Mermaid.js diagrams (Flowcharts, Sequence Diagrams, ER Diagrams for PostgreSQL) inside the `architecture.md` file.

*   **Complexity**: **Low**
*   **Benefit**: **Medium**
*   **Impact**: Makes complex, cross-repository requirements immediately visual and digestible for human developers reviewing the AI's architectural proposals.

## 3. AI-Managed Tech Debt Queue

During the `#review` and `#reflect` phases, the AI often notices suboptimal code or out-of-scope improvements that get lost in the chat window. This instructs the `#wrapup` agent to automatically extract these items and write them to a `.forge/backlog/` directory using the standard `requirement-template.md`.

*   **Complexity**: **Medium**
*   **Benefit**: **High**
*   **Impact**: Prevents continuous AI iteration from accumulating hidden technical debt. It ensures that minor refactoring opportunities are systematically captured and tracked.

## 4. MCP (Model Context Protocol) Knowledge Retrieval

The current system relies on VS Code's standard tools to read flat `.md` files in `.forge/knowledge/lessons/`. As the project scales, reading all lessons consumes too much of the context window. Implementing an MCP server would act as a localized RAG (Retrieval-Augmented Generation) system.

*   **Complexity**: **High**
*   **Benefit**: **Very High**
*   **Impact**: Enables Copilot to dynamically fetch only the exact 2 or 3 lessons relevant to the specific file or component being worked on, allowing the repository's "brain" to scale infinitely without hitting token limits.

## 5. Automated CI/CD SDD Verification

Currently, validation and review happen locally in the developer's VS Code via `#validate` and `#review`. This improvement implements a GitHub Action (or GitLab CI pipeline) that uses the OpenAI API to automatically cross-reference the PR diff against the original `REQ-xxx/requirement.md`.

*   **Complexity**: **High**
*   **Benefit**: **High**
*   **Impact**: Enforces Spec-Driven Development at the repository level. A developer cannot merge code if the automated CI pipeline detects that the implementation has drifted from the agreed-upon specification.

## 6. Automated Rollback in `#canary`

The `#canary` prompt currently manages smoke tests and promotes successful deployments. This upgrade adds explicit rollback intelligence: if the smoke test fails post-deployment on the AKS cluster, the agent automatically executes a `helm rollback` or `kubectl rollout undo`.

*   **Complexity**: **High**
*   **Benefit**: **Medium**
*   **Impact**: Dramatically increases deployment safety by ensuring that broken, AI-generated code that slips past local reviews is instantly reverted in the integration/staging environments without human panic.
