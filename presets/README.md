# Presets

Stack-shaped starter configs for `.forge/config.yml`. Each preset captures a common combination of platforms, deploy targets, and CI patterns. Pick the one closest to your stack, copy it into your repo, and replace the placeholder values.

## Available presets

| File | Stack | Use for |
|------|-------|---------|
| [springboot-postgres-aks.yml](springboot-postgres-aks.yml) | Java Spring Boot + PostgreSQL + AKS (shared cluster) + ACR + Helm + GitHub Actions | Backend/API repo in a Java stack |
| [react-aks.yml](react-aks.yml) | React (TypeScript) + AKS (shared cluster) + ACR + Helm + nginx Ingress + GitHub Actions | Frontend/web repo in any AKS stack |

## How to use a preset

From inside the repo where you're running `#init`:

```powershell
# PowerShell — backend repo
Copy-Item \path\to\copilot-forge\presets\springboot-postgres-aks.yml .forge\config.yml

# PowerShell — frontend repo
Copy-Item \path\to\copilot-forge\presets\react-aks.yml .forge\config.yml
```

```bash
# bash / zsh — backend repo
cp /path/to/copilot-forge/presets/springboot-postgres-aks.yml .forge/config.yml

# bash / zsh — frontend repo
cp /path/to/copilot-forge/presets/react-aks.yml .forge/config.yml
```

Replace every `<placeholder>` with a real value (project name, AKS cluster name, namespace, ACR paths). Don't leave placeholders in — prompts will surface missing values loudly, but it's faster to fill them in up front.

## What's a preset, exactly

A preset is **stack shape, not company configuration**. It declares:

- Which platforms are in play (`stack.frontends: [web]`, `stack.backends: [k8s]`)
- Which sections are populated (e.g., `aks:` and `acr:` blocks present, with placeholder values)
- Sensible defaults (e.g., `build.tool: maven`, `build.java_version: 21`)
- Example shape for the `services:` block

It does **not** contain:

- Real project IDs, repo names, account IDs, secrets
- Specific device names — leave those as placeholder strings
- Anything proprietary to a specific company's setup

## Adding a new preset

If you have a stack combination not covered here, drop a new YAML file in this directory and update the table above. Naming convention: `<frontend>-<auth-or-data-layer>-<backend-platform>.yml`. Examples:

- `web-supabase-vercel.yml`
- `react-postgres-k8s.yml`
- `none-postgres-k8s.yml`

Open a PR against the canonical `copilot-forge` upstream — presets benefit from being shared.
