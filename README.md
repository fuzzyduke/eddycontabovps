# Eddy VPS Platform

This repository is the **Source of Truth** for the Eddy Contabo VPS. It uses a fully deterministic, GitHub-driven deployment workflow.

## 🏗️ Architecture
- **Infrastructure**: Traefik-based reverse proxy with automated SSL.
- **Orchestration**: Docker Compose (no Swarm, no Dokploy).
- **Automation**: Root level `deploy.sh` manages all stacks.
- **Trigger**: GitHub Actions on push to `main`.

## 📁 Repository Structure
- `/.github/workflows/`: CI/CD pipelines.
- `/apps/`: Individual application stacks (e.g., `eddyclawd`).
- `/infra/`: Shared infrastructure (Traefik, networks).
- `/docs/`: Standard Operating Procedures and Rules.

## 🚀 Deployment Workflow
1. Commit changes to `/apps` or `/infra`.
2. Push to `main`.
3. GitHub Actions SSHs into the VPS and executes `/srv/deploy.sh`.
4. The system detects changed folders, validates configuration, and redeploys safely.

## 🛡️ Safety & Reliability
- **Drift Protection**: Deployment fails if uncommitted local changes exist on the VPS.
- **Validation**: Every stack is validated via `docker compose config` before restart.
- **Health Checks**: Deployment waits for containers to be healthy.
- **Upgrades**: Versioned upgrades are handled via `UPGRADE.md` scripts.

## 🛠️ Adding New Apps

To publish a new application to the platform, follow the **New App Deploy Pipeline**:

1.  **Read the SOP**: [NEW_APP_SOP.md](./docs/NEW_APP_SOP.md) for hard constraints and commands.
2.  **Follow the Checklist**: Use [PUBLISH_NEW_APP.md](./docs/PUBLISH_NEW_APP.md) as your fill-in-the-blanks deployment tracking.
3.  **Use the Helper**:
    ```bash
    ./scripts/new_app_scaffold.sh <APP_NAME> <SUBDOMAIN> <INTERNAL_PORT>
    ```

### Important rules
- **Secrets**: Must be added to the private **Bible** repo under `vps/<APP_NAME>.env`.
- **Infrastructure**: Use pinned image tags, set resource limits, and attach to the `proxy` network.
- **Verification**: Always verify with `curl -I` and Traefik logs after deployment.
