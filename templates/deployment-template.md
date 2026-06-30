# {Project Name} — Deployment Flow

*Navigation: [Project Overview](project-overview.md) | [Architecture](architecture.md) | [Conventions](conventions.md) | [Variables](variables.md)*

## CI/CD Pipeline Overview

_Describe the overall continuous integration and continuous deployment pipeline._

- **Tooling**: (e.g., GitHub Actions, GitLab CI, Jenkins, ArgoCD)
- **Environments**: (e.g., Development, Staging, Production)

## Environments & Targets

| Environment | Branch Trigger | Target Infrastructure | URL / Endpoint |
|-------------|----------------|-----------------------|----------------|
| Staging | `main` | (e.g., AWS ECS, AKS) | `https://staging...` |
| Production | `release/*` | (e.g., AWS ECS, AKS) | `https://prod...` |

## Build Process

_Describe how artifacts (Docker images, binaries, zip files) are built and packaged._

- **Build Tool**: (e.g., Docker, Maven, Webpack, Vite)
- **Artifact Registry**: (e.g., ECR, ACR, Docker Hub)

## Local Deployment / Run Steps

_Step-by-step sequence of how to run this project locally for testing or development._

1. [e.g., `npm install`]
2. [e.g., `npm run build`]
3. [e.g., `npm run start` or `docker-compose up`]

## Remote Deployment Steps

_Step-by-step sequence of what happens during a deployment._

1. [Trigger] (e.g., Push to `main`)
2. [Test] (e.g., Run unit and integration tests)
3. [Build] (e.g., Build Docker image and tag with commit hash)
4. [Deploy] (e.g., Update Kubernetes deployment manifest)
5. [Verify] (e.g., Run smoke tests)

## Rollback Procedure

_How to safely revert a deployment if something goes wrong._

- [Rollback steps]

## Required Secrets / Variables

_List external secrets needed for deployment (do NOT store actual values here, only keys)._

- (e.g., `AWS_ACCESS_KEY_ID`, `DOCKER_REGISTRY_TOKEN`)

## Internal Reference
- **Incoming Dependencies**: `#forge-init`
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*