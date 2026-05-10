---
id: REQ-xxx
title: "Feature Title"
status: draft
deployable: true
created: YYYY-MM-DD
updated: YYYY-MM-DD
component: ""       # narrow area, e.g., "API/auth", "iOS/SwiftUI", "Copilot Forge/spec"
domain: ""          # broad area, e.g., "auth", "payments", "ui"
stack: []           # tech layers touched, e.g., ["express", "postgres"]
concerns: []        # cross-cutting dimensions, e.g., ["security", "performance", "a11y"]
tags: []            # free-form keywords, e.g., ["password-reset", "tokens"]
---

## 1. WHAT (System Capabilities & Data)

_Define the exact data structures, schemas, and API boundaries. What is the system managing?_

### Entities

| Entity | Field | Type | Constraints |
|--------|-------|------|-------------|
| [EntityName] | [field] | [string/number/boolean/timestamp] | [required, unique, max length, etc.] |

## 2. WHO (Identity & Access)

_Define the actors, roles, and security perimeters. Who is allowed to do what?_

| Actor / Role | Permission | Condition |
|--------------|------------|-----------|
| [RoleName] | [action] | [e.g., "Must own the resource"] |

## 3. WHEN (Event Flows & Triggers)

_Define the pulse of the feature. What triggers this functionality?_

| Event | Trigger | Payload / State Change |
|-------|---------|------------------------|
| [event_name] | [What causes it, e.g., Cron, API call] | [Data included or changed] |

## 4. WHERE (Infrastructure & Environment)

_Define the deployment boundaries and network constraints._

- [ ] Environment: [e.g., AKS, Cloud Run, AWS Lambda]
- [ ] Network: [e.g., Public API, Internal VPN, VPC only]
- [ ] Dependencies: [e.g., Requires external Payment API]

## 5. WHY (Business Rules & Invariants)

_Explicit, testable constraints that must never be broken (the logical North Star)._

- [ ] BR-1: [Rule statement — e.g., "Only item owner can delete wardrobe items"]
- [ ] BR-2: [Rule statement]

## 6. HOW (Implementation & Tech Stack)

_Define the foundational architecture/stack this feature binds to (prevents AI guessing)._

- [ ] Stack: [e.g., React frontend + Spring Boot backend]
- [ ] Architecture Pattern: [e.g., REST API, GraphQL, Event-Driven]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Assumptions

- None

## Open Questions

- [ ] Open question 1

## Out of Scope

- Items explicitly excluded
