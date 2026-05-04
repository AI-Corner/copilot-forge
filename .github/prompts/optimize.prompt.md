---
agent: agent
tools: [codebase, runCommand, terminalLastCommand]
description: API cost & performance scanner — identify expensive operations and optimization opportunities
---

# optimize — API Cost & Performance Scanner

You are scanning this project's API and infrastructure for cost and performance optimization opportunities.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.


## Input

Focus: [specific focus area — "ai", "caching", "queries", "latency" — or nothing for all dimensions]

## Instructions

### Step 1: Determine Focus
1. If given a focus area, prioritize that dimension.
2. If no argument, scan all dimensions.
3. Read `.forge/context/architecture.md` and `.forge/context/project-overview.md` via the codebase tool for current caching and optimization patterns.

### Step 2: Run Scanner Dimensions Sequentially

#### Dimension 1 — API Cost Analysis (reference: `#agents/api-cost-scanner`)
Use the codebase tool to find all AI API call sites:
- **AI API Call Inventory**: find all AI API calls (grep for OpenAI SDK imports and `.create(`, `chat.completions`, etc.). For each call: which model, estimated token usage per request, frequency.
- **Model Selection**: calls using expensive frontier models that could use cheaper/faster alternatives. Tasks where model capability exceeds what's actually needed.
- **Caching Strategy**: check for prompt caching usage. Identify system prompts re-sent on every call. Check L1 (in-memory) and L2 (DB) cache effectiveness.
- **Redundant Calls**: duplicate AI calls for the same input, calls that could be replaced with deterministic logic, speculative calls often discarded.
- **Cost Estimates**: estimate per-call cost and monthly volume.

#### Dimension 2 — Database Performance (reference: `#agents/db-perf-scanner`)
Use the codebase tool to grep for JDBC, JPA, and Spring Data call patterns:
- **Query Issues**: missing indexes on frequently filtered columns, unbounded queries (no `Pageable`/`LIMIT`), N+1 patterns, read-after-write that could reuse the write result, `SELECT *` where projections suffice.
- **Connection Pool**: missing HikariCP config, pool exhaustion, connections not released.
- **Pagination**: list endpoints returning all rows, missing `Pageable` on repository methods.
- **Atomic Operations**: counter updates not using atomic SQL, missing `@Transactional` on multi-step writes.
- **Batch Operations**: sequential `save()` calls that could use `saveAll()`, N selects that could be one IN-clause query.
- **Cache Effectiveness**: frequently read data not cached with `@Cacheable`, missing `@CacheEvict` on writes.

#### Dimension 3 — Latency Analysis (reference: `#agents/latency-scanner`)
Use the codebase tool to trace request paths from controller through service to repository:
- **Sequential Blocking Calls**: service methods making multiple independent DB or HTTP calls in series — prefer `CompletableFuture.allOf()` or parallel streams.
- **Response Payload Sizes**: over-fetching (returning full entity when only a few fields are needed), missing DTO projections, large nested objects that could be lazy-loaded.
- **Controller / Filter Overhead**: auth token verification not cached, expensive filters running before cheap ones, unnecessary filter chain entries.
- **Thread Pool Sizing**: `@Async` thread pool defaults too small for I/O-heavy workloads, unbounded thread pools.
- **General Throughput**: synchronous blocking in reactive contexts, missing connection pool tuning, missing request timeouts on outbound HTTP calls (`RestTemplate` / `WebClient`).

### Step 3: Build Optimization Report

#### Cost Summary
| Service | Est. Monthly Usage | Est. Monthly Cost | Top Optimization |
|---------|-------------------|-------------------|------------------|
| OpenAI API | X calls | $X | ... |
| PostgreSQL | X queries/sec | $X (infra) | ... |

#### Performance Hotspots
Rank endpoints by estimated latency, highlighting:
- Sequential operations that could be parallel
- Missing caches
- N+1 query patterns
- Unnecessary data fetching

#### Optimization Opportunities
For each opportunity:
- **What**: Description of the optimization
- **Impact**: Cost savings or latency reduction estimate
- **Effort**: Small / Medium / Large
- **Risk**: Low / Medium / High

### Step 4: Prioritized Recommendations
1. Rank optimizations by impact/effort ratio.
2. Group into quick wins (small effort, high impact) and strategic improvements.
3. Suggest which items warrant a full Copilot Forge requirement (candidates for `#spec`).
