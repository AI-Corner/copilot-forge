# Copilot Forge — Roadmap & Future Enhancements

This document outlines strategic improvements to the Copilot Forge toolkit to further optimize Spec-Driven Development (SDD) for enterprise use, particularly for robust multi-service architectures (like Java Spring Boot + React + PostgreSQL + AKS).

## Feature Tracking Overview

| # | Feature | Status | Complexity | Impact |
|---|---------|--------|------------|--------|
| 1 | Test-Driven Development (TDD) First Prompts | ✅ Implemented | Low | High |
| 2 | Interactive Architecture Diagrams (Mermaid.js) | ✅ Implemented | Low | Medium |
| 3 | AI-Managed Tech Debt Queue | ⚠️ Partial | Medium | High |
| 4 | MCP (Model Context Protocol) Knowledge Retrieval | 🚧 Future | High | Very High |
| 5 | Automated CI/CD SDD Verification | 🚧 Future | High | High |
| 6 | Automated Rollback in `#canary` | ✅ Implemented | High | Medium |
| 7 | Environment & Configuration Variable Mapping | ✅ Implemented | Medium | High |
| 8 | Cross-Application Access Flow Tracking | 🚧 Future | Medium | High |
| 9 | Application Monitoring & Observability Knowledge | 🚧 Future | Low | Medium |
| 10 | Architectural Evolution: Subagent-Driven via CLI | 🚧 Future | High | High |
| — | Automated Support Documentation Generation | ✅ Implemented | Low | Medium |

> **Status legend**: ✅ Implemented · ⚠️ Partial · 🚧 Future

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

## 7. Environment & Configuration Variable Mapping

Currently, Copilot Forge establishes knowledge baselines for architecture, flows, domain, and functional logic. This upgrade introduces an automated mechanism to extract, document, and track all configuration variables (e.g., frontend `.env` vars, backend `application.yml` properties, CI/CD secrets). It will act as a centralized dictionary to map where variables are defined, where they are consumed, and their intended purpose.

*   **Complexity**: **Medium**
*   **Benefit**: **High**
*   **Impact**: Prevents "missing secret" deployment crashes, aids in rapid debugging, and provides AI agents with explicit awareness of configuration toggles across both frontend and backend domains.

## 8. Cross-Application Access Flow Tracking

For complex multi-modal applications spanning multiple repositories (e.g., frontend clients, API gateways, backend microservices), tracing authentication and authorization logic can become extremely difficult. This enhancement introduces a standardized knowledge base artifact (e.g., `.forge/context/access-flow.md`) designed to track how access controls, identities, JWTs, and session tokens are provisioned, passed, and validated both *within* a single application boundary and *across* applications in a shared workspace.

*   **Complexity**: **Medium**
*   **Benefit**: **High**
*   **Impact**: Empowers the AI to confidently navigate, validate, and architect security and authorization logic across multiple repositories. It ensures that token passing, role verifications, and cross-application permissions remain secure and strictly documented.

## 9. Application Monitoring & Observability Knowledge

Once an application is deployed, understanding its health, logs, and performance metrics is crucial. This enhancement introduces a standardized knowledge base artifact (e.g., `.forge/context/observability.md`) to document how the application is monitored. This includes tracking structured logging formats, key performance metrics (APM), health check endpoints, alert thresholds, and dashboard configurations (e.g., Datadog, Prometheus/Grafana, or ELK stack integration).

*   **Complexity**: **Low**
*   **Benefit**: **Medium**
*   **Impact**: Provides AI agents with the necessary context to intelligently suggest observability improvements, generate appropriate logging statements during implementation, and help debug production issues by knowing exactly where and how to look at the telemetry data.

## 10. Architectural Evolution: Subagent-Driven Development via CLI

Currently, Copilot Forge relies heavily on the VS Code Copilot Chat GUI for its execution pipeline (`#proceed`). While effective for maintaining context through the ideation and architecture phases, running a continuous pipeline in a single chat window leads to context bloat and increased hallucinations on large features. 

The planned evolution is to transition the execution phase (Task Implementation & Review) to a **Subagent-Driven** model orchestrated by terminal scripts leveraging the **Copilot CLI** (`gh copilot`).

### Pros & Cons of Subagents vs. Single Context Window
*   **Pro - The "Hallucination Tax" is Eliminated:** In a long continuous thread, context grows linearly, causing the AI to mix up code from Task 1 with Task 5. Subagents operate in pristine, isolated environments, drastically reducing rework and debugging loops.
*   **Pro - Perfect Isolation:** Task 1's bugs or conversational missteps cannot pollute Task 3's brain.
*   **Con - The "Context Tax":** You must re-feed baseline context (the Zachman spec, architecture rules, codebase state) to every new subagent. This increases *input* token usage, though modern Prompt Caching significantly offsets this cost.

### Why the Copilot CLI Solves This
The VS Code Chat GUI naturally retains conversational memory, making it difficult to "wipe" the agent's brain between tasks. A CLI tool is inherently stateless. 
By moving the execution pipeline to an automated script (e.g., `proceed.ps1`), the orchestrator can:
1. Parse the task list generated in the Architecture phase.
2. Spin up a completely fresh `gh copilot` execution for Task 1, passing it only the required artifacts.
3. Spin up a fresh execution for the `#reflect` checklist.
4. Move to Task 2 with zero conversational bleed-over.

*   **Complexity**: **High**
*   **Benefit**: **High**
*   **Impact**: Allows Copilot Forge to scale autonomously to handle massive, multi-task features without suffering from the context degradation and hallucinations typical of continuous LLM chat sessions.
