# Deployment Rules

1. **Zero-Traffic Canary First**: All deployments MUST be initiated as zero-traffic canary revisions. Use `--no-traffic --tag=canary`.
2. **Mandatory Smoke Tests**: A canary revision MUST pass all defined smoke tests (at a minimum, `/health` and `/api/health` returning 200 OK) before it can be promoted.
3. **Automated Rollback**: If health checks or smoke tests fail, the canary tag MUST be immediately removed, keeping production traffic unchanged.
4. **Environment Check**: Ensure `gcloud` is authenticated and configured before starting any deployment.
