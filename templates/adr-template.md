<!--
Filename MUST be `ADR-xxx-slug.md` (e.g., `ADR-012-use-graphql-for-public-api.md`).
- `xxx` is the next available integer, zero-padded to 3 digits, unique across `.forge/knowledge/decisions/`.
- `slug` is lowercase kebab-case, ≤6 words.
-->
---
id: ADR-xxx
title: "Decision Title"
status: "proposed"  # proposed, accepted, deprecated, superseded
component: ""       # narrow area, e.g., "API/auth", "frontend/state"
domain: ""          # broad area, e.g., "architecture", "data-layer"
stack: []           # tech layers touched, e.g., ["react", "graphql"]
concerns: []        # cross-cutting dimensions, e.g., ["performance", "security"]
req: REQ-xxx        # requirement that prompted this decision
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

## Context

Brief description of the problem or requirement that requires a decision. What are the competing forces or constraints?

## Decision

The architectural or technical choice being made. What are we deciding to do? (e.g., "We will use GraphQL instead of REST for all new public-facing endpoints.")

## Rationale

Why was this chosen over the alternatives? What makes this the best fit for our specific context?

## Consequences

What are the downstream effects of this decision?
- **Positive:** Benefits we gain.
- **Negative:** Tradeoffs we accept, new risks, or added complexity.

## Internal Reference
- **Incoming Dependencies**: `#query`, `#init`, `#architect`, `#wrapup`
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*