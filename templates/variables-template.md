# Environment & Configuration Variables

> [!CAUTION]
> **SECURITY WARNING:** Do NOT store real production secrets, API keys, passwords, or sensitive tokens in this file. This file is intended to be committed to version control and must only contain variable names, dummy/example values, or safe development default values.

This document serves as the central registry for all configuration properties, environment variables, and secrets used across the project. It provides AI agents and developers with explicit knowledge of the application's configuration surface to prevent missing secrets and deployment crashes.

# Part 1: Application Variables

## Frontend Variables

Environment variables consumed by the frontend application (e.g., React `REACT_APP_*`, Vite `VITE_*`, Next.js `NEXT_PUBLIC_*`).

| Environment | Variable Key | Default/Example Value | Purpose | Consumers |
|-------------|--------------|-----------------------|---------|-----------|
| Local/Dev   | `VITE_API_BASE_URL` | `http://localhost:8080/api` | Base URL for API | `src/api/client.ts` |
| Staging     | `VITE_API_BASE_URL` | `https://stg-api.demo.com` | Base URL for API | `src/api/client.ts` |
| Prod        | `VITE_API_BASE_URL` | `https://api.demo.com` | Base URL for API | `src/api/client.ts` |
| All         | `VITE_ENABLE_MOCK` | `false` | Toggles mock data | `src/main.tsx` |

## Backend Properties

Configuration properties and environment variables consumed by the backend services (e.g., Spring Boot `application.yml`, Node `process.env`).

| Environment | Variable Key | Default/Example Value | Purpose | Consumers |
|-------------|--------------|-----------------------|---------|-----------|
| Local/Dev   | `DB_HOST` | `localhost` | Database hostname | `application.yml` |
| Prod        | `DB_HOST` | `db.production.internal` | Database hostname | `application.yml` |
| All         | `JWT_SECRET` | `dummy-secret-key` | Token signing secret. | `jwt.service.ts` |
| All         | `PORT` | `3000` | HTTP port | `src/index.ts` |

# Part 2: Infrastructure Creation Variables

## Infrastructure & Deploy Secrets

Variables and secrets used in CI/CD pipelines, container orchestration, or cloud environments (e.g., GitHub Secrets, Kubernetes Secrets, Helm Values).

| Environment | Variable Key | Default/Example Value | Purpose | Consumers |
|-------------|--------------|-----------------------|---------|-----------|
| All         | `DOCKER_REGISTRY_TOKEN` | `dummy-token` | Image push token | `.github/workflows/build.yml` |
| Staging     | `AKS_CLUSTER_NAME` | `stg-cluster` | Target Kubernetes cluster | `helm/values-stg.yaml` |
| Prod        | `AKS_CLUSTER_NAME` | `prod-cluster` | Target Kubernetes cluster | `helm/values-prod.yaml` |

## Internal Reference
- **Incoming Dependencies**: `#forge-init`
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*