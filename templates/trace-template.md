# forge-trace

Query and summarize observability traces recorded by Langfuse for Copilot Forge pipeline runs.

## Description
This prompt allows you to query telemetry metrics, trace hierarchies, token usages, and gate status for pipeline execution runs.

## Usage
- `#forge-trace REQ-101` — Retrieve the trace hierarchy and status for `REQ-101`.
- `#forge-trace REQ-101 --failed` — Show only failed spans or computational/inferential gate failures.
- `#forge-trace --last 5` — List the 5 most recent pipeline traces with latency and token consumption summaries.

## Workflow Instructions
1. Inspect `.env.local` to check if `LANGFUSE_HOST` and API keys are set.
2. Query the Langfuse API endpoint (`/api/public/traces`) using PowerShell or curl if credentials exist.
3. If Langfuse is offline or unconfigured, fall back to checking `pipeline-state.json` or local phase output logs.
4. Output a summary structured table containing: Phase, Status, Tokens In, Tokens Out, Latency (ms), and Gate Errors.
