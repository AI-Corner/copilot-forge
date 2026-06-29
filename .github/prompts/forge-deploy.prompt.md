---
agent: agent
tools: [codebase, runCommand, terminalLastCommand]
description: Deploy or run the current project locally or to a specific environment
---

# deploy — Deployment Automation

You are automating the deployment or local execution of the project based on the defined `.forge/context/deployment.md`.

> **Ethos**: Follow the principles in `.github/copilot-instructions.md` throughout this session.

## Input

Deployment target: [provided by the user — defaults to "local" if omitted]

## Prerequisites

Before proceeding:
1. Use the codebase tool to verify `.forge/context/deployment.md` exists. If it doesn't, stop and tell the user: "The deployment context hasn't been initialized. Ensure `.forge/context/deployment.md` exists or run `#forge-init` again."
2. Read `.forge/context/deployment.md` for deployment workflows.

## Instructions

### Step 1: Determine Deployment Target
1. If the user did not specify a target (e.g., they just typed `#forge-deploy`), assume "local" but ask for confirmation: "Deploying locally. If you meant to deploy to staging or production, please specify: `#forge-deploy staging`".
2. If the user specified a target (e.g., `local`, `staging`, `production`), identify the corresponding steps in `.forge/context/deployment.md`.

### Step 2: Secret Verification
1. Check the "Required Secrets / Variables" section of `.forge/context/deployment.md`.
2. If secrets are required for the chosen target, read `.forge/.env.local`.
3. If any required secret is missing from `.forge/.env.local`, stop and instruct the user: "Missing required deployment secrets. Please add them to `.forge/.env.local` before proceeding." Do not proceed until they are added.

### Step 3: Execute Deployment Steps
Use the `runCommand` tool to sequentially execute the deployment steps defined in `.forge/context/deployment.md` for the chosen target.
- For **local** deployments, follow the "Local Deployment / Run Steps".
- For **remote** deployments, follow the "Remote Deployment Steps".

If a command fails, use `terminalLastCommand` to check the error and attempt to fix it, or halt and ask the user for guidance.

### Step 4: Verification
Once the deployment commands are complete, verify the deployment if verification steps are provided (e.g., pinging a health endpoint via `runCommand` curl, or checking a local port).

Inform the user of the successful deployment and provide the accessible URL/Endpoint if applicable.

## Internal Reference
- **Incoming Skill Dependencies**: *None*
- **Incoming Agent Dependencies**: *None*
- **Outgoing Skill Dependencies**: *None*
- **Outgoing Agent Dependencies**: *None*
- **Resource Dependencies**: *None*
