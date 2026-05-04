# Environment & Configuration Variables

> [!CAUTION]
> **SECURITY WARNING:** Do NOT store real production secrets, API keys, passwords, or sensitive tokens in this file. This file is intended to be committed to version control and must only contain variable names, dummy/example values, or safe development default values.

This document serves as the central registry for all configuration properties, environment variables, and secrets used across the project. It provides AI agents and developers with explicit knowledge of the application's configuration surface to prevent missing secrets and deployment crashes.

## Frontend Variables

Environment variables consumed by the frontend application (e.g., React `REACT_APP_*`, Vite `VITE_*`, Next.js `NEXT_PUBLIC_*`).

| Variable Key | Type/Format | Default Value | Purpose | Consumers (Files/Components) |
|--------------|-------------|---------------|---------|------------------------------|
| `VITE_API_BASE_URL` | URL string | `http://localhost:8080/api` | Base URL for backend API requests | `src/api/client.ts` |
| `VITE_ENABLE_MOCK_DATA` | boolean | `false` | Toggles mock data for local development | `src/main.tsx` |

## Backend Properties

Configuration properties and environment variables consumed by the backend services (e.g., Spring Boot `application.yml`, Node `process.env`).

| Variable Key | Type/Format | Default Value | Purpose | Consumers (Files/Components) |
|--------------|-------------|---------------|---------|------------------------------|
| `DB_HOST` | string | `localhost` | Database hostname | `config/database.js`, `application.yml` |
| `JWT_SECRET` | string | `dummy-secret-key` | Secret key for signing JWT tokens. DO NOT USE REAL SECRET HERE. | `src/auth/jwt.service.ts` |
| `PORT` | number | `3000` | HTTP port the server listens on | `src/index.ts` |

## Infrastructure & Secrets

Variables and secrets used in CI/CD pipelines, container orchestration, or cloud environments (e.g., GitHub Secrets, Kubernetes Secrets, Helm Values).

| Variable Key | Type/Format | Default Value | Purpose | Consumers (Files/Components) |
|--------------|-------------|---------------|---------|------------------------------|
| `DOCKER_REGISTRY_TOKEN` | string | `dummy-token` | Used by GitHub Actions to push images to registry | `.github/workflows/build.yml` |
| `AKS_CLUSTER_NAME` | string | `my-cluster` | Name of the target Kubernetes cluster for deployment | `helm/values.yaml` |
