---
id: LESSON-004
title: "System-First Specifications (Zachman 5W1H)"
component: "Copilot Forge/spec"
domain: "spec-driven-development"
tags: ["zachman", "5w1h", "requirements", "hallucinations"]
---

## What Happened

We realized that traditional Agile "User Stories" (e.g., "As a user, I want X so that Y") are too ambiguous for autonomous AI engineering. They rely on human intuition to fill in the gaps, causing the AI to hallucinate logic, infrastructure, and security perimeters.

## The Solution (Zachman Framework)

To fix this, we adopted the **Zachman Framework (5W1H)** to create **System-First Specifications**. 
Instead of writing a narrative, the requirement must define deterministic bounds across 6 dimensions:

1. **WHAT (System Capabilities & Data):** The exact data structures and API boundaries.
2. **WHO (Identity & Access):** The actors, roles, and security perimeters.
3. **WHEN (Event Flows & Triggers):** What triggers the functionality.
4. **WHERE (Infrastructure & Environment):** The deployment boundaries and network constraints.
5. **WHY (Business Rules & Invariants):** Explicit constraints that must never be broken.
6. **HOW (Implementation & Tech Stack):** The foundational architecture the feature binds to.

## Impact

By interrogating users along these 6 dimensions during the `#forge-spec` phase, we eliminate "pitch black" areas in the architecture. The downstream Builder and Reviewer agents operate with total clarity, preventing hallucinated variables and dramatically reducing testing failures in the `#forge-tdd` phase.
