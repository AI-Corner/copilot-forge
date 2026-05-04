---
agent: agent
tools: [codebase, runCommand, changes, terminalLastCommand]
description: Canary deployment — deploy a zero-traffic revision, run smoke tests, promote on success
---

# canary — Canary Deployment with Smoke Tests

You are deploying code through a canary process: deploy a zero-traffic revision, verify it works, then promote to live traffic. This prevents broken deploys from reaching users.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Target: [repo id from `.forge/config.yml`, Cloud Run service name, or nothing for auto-detection — provided by the user]

## Prerequisites

1. `gcloud` CLI must be authenticated and configured with the correct project.
2. The service must already exist on Cloud Run.
3. A Docker image must be available.

## Service Resolution

Service configuration lives in `.forge/config.yml` under a `services:` block, keyed by repo id. Read this file via the codebase tool.

**Resolution order**:
1. If the argument is a repo id defined under `repos:` in the config, look up `services[<repo-id>]`.
2. If the argument is a Cloud Run service name matching `services.*.cloud_run_service`, use that entry.
3. If no argument: detect which repo the current workspace is inside by matching against `repos[*].path`. Then look up its service.
4. If the project has no `.forge/config.yml` AND the repo has a top-level `Dockerfile`, fall back: service name = repo basename, region = `us-central1`.
5. If none resolves, stop: "Could not determine Cloud Run service. Add a `services:` block to `.forge/config.yml` or pass the service name as an argument."

## Instructions

### Step 1: Build and Push Image
Run in terminal:
```bash
SHA=$(git rev-parse --short HEAD)
IMAGE_PATH=<resolved from config>
docker build -t ${IMAGE_PATH}:canary-${SHA} .
docker push ${IMAGE_PATH}:canary-${SHA}
```
If the user says "use latest" or the image was built by CI, skip the build and use the `:latest` tag.

### Step 2: Deploy Canary Revision (Zero Traffic)
```bash
gcloud run deploy <SERVICE_NAME> \
  --image=<IMAGE_PATH>:canary-<SHA> \
  --region=<region from config> \
  --no-traffic \
  --tag=canary \
  --format="json"
```
Capture the canary URL from the output (the tagged revision URL).

### Step 3: Health Checks
```bash
# Retry up to 3 times with 5-second intervals (cold start grace period)
curl -s -o /dev/null -w "%{http_code}" <CANARY_URL>/health
curl -s -o /dev/null -w "%{http_code}" <CANARY_URL>/api/health
```
Expected: `200`. If health checks fail after 3 retries, go to Step 6 (Rollback).

### Step 4: Smoke Tests
Read `.forge/context/smoke-tests.md` if it exists for custom test definitions. Otherwise use defaults:
```
GET  /health      -> 200
GET  /api/health  -> 200
```

For each test:
```bash
RESPONSE=$(curl -s -w "\n%{http_code}" <CANARY_URL><PATH>)
STATUS=$(echo "$RESPONSE" | tail -1)
```

Report results:
```
## Smoke Test Results

| Test | Method | Path | Expected | Actual | Status |
|------|--------|------|----------|--------|--------|
| Health | GET | /health | 200 | 200 | PASS |

Result: 2/2 passed
```
If any test fails, go to Step 6 (Rollback).

### Step 5: Promote to Production
```bash
gcloud run services update-traffic <SERVICE_NAME> \
  --region=<region> \
  --to-tags=canary=100

# Verify
gcloud run services describe <SERVICE_NAME> \
  --region=<region> \
  --format="table(status.traffic[].percent,status.traffic[].revisionName)"

# Clean up canary tag
gcloud run services update-traffic <SERVICE_NAME> \
  --region=<region> \
  --remove-tags=canary
```

Report:
```
Canary promoted to production.
Service: <SERVICE_NAME>
Revision: <REVISION_NAME>
All smoke tests passed.
```

### Step 6: Rollback (Failure Path)
```bash
gcloud run services update-traffic <SERVICE_NAME> \
  --region=<region> \
  --remove-tags=canary
```
Report:
```
CANARY FAILED — rolled back.
Service: <SERVICE_NAME>
Failed revision: canary-<SHA>
Failures: [list failed checks]
Production traffic is unchanged.
```
Suggest: `gcloud run services logs read <SERVICE_NAME> --region=<region> --limit=50`

### Step 7: Update Pipeline State (if in #proceed context)
If `pipeline-state.json` exists for the current REQ, add a `canary` entry to `phaseHistory` with the result (passed/failed), service name, revision, and smoke test results.
