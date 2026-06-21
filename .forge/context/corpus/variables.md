# Environment & Configuration Variables

> [!CAUTION]
> **SECURITY WARNING:** Do NOT store real production secrets, API keys, passwords, or sensitive tokens in this file. This file is intended to be committed to version control and must only contain variable names, dummy/example values, or safe development default values.

This document serves as the central registry for all configuration properties, environment variables, and secrets used across the Copilot Forge toolkit repository.

## Frontend Variables

*N/A - Copilot Forge does not have a frontend application.*

| Variable Key | Type/Format | Default Value | Purpose | Consumers (Files/Components) |
|--------------|-------------|---------------|---------|------------------------------|
| N/A | | | | |

## Backend Properties

*N/A - Copilot Forge does not have a backend service.*

| Variable Key | Type/Format | Default Value | Purpose | Consumers (Files/Components) |
|--------------|-------------|---------------|---------|------------------------------|
| N/A | | | | |

## Infrastructure & Secrets

Variables and secrets used in CI/CD pipelines, container orchestration, or cloud environments. As of current development, the core Copilot Forge toolkit relies on standard GitHub environment contexts.

| Variable Key | Type/Format | Default Value | Purpose | Consumers (Files/Components) |
|--------------|-------------|---------------|---------|------------------------------|
| `GITHUB_TOKEN` | string | `dummy-token` | Implicitly used by GitHub extensions and `gh` CLI commands run in prompt instructions | `.github/prompts/init.prompt.md` (implied usage via `gh` or git) |
