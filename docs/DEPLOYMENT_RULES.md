# Eddy VPS Deployment Rules (Hardened)

## 1. Repository Contract
Every app in `/apps/<app-name>` must follow these rules:
- **Isolation**: Each app MUST have its own `docker-compose.yml`.
- **Resources**: Each service MUST have `deploy.resources.limits`.
- **Health**: Containers SHOULD have a `healthcheck`. If not, set `ALLOW_NO_HEALTHCHECK=1` or rely on container state monitoring.

## 2. Infrastructure
- Shared configs live in `/infra`.
- Traefik manages all host-level routing.

## 3. Automated Hardened Upgrades (`upgrade.sh`)
- If manual steps are needed, provide an **executable** `upgrade.sh`.
- **Opt-in**: Upgrades only run if `RUN_UPGRADES=1` is set in the environment.
- **Safety**: The engine scans for blacklisted commands (`docker system prune`, etc.).
- **Rollback**: Failure in `upgrade.sh` triggers an automatic rollback.

## 4. Git as Source of Truth
- Local changes on the VPS are considered "drift" and will block deployments.
- The VPS state is strictly reset to `origin/master` on every push.

## 5. Deployment Safety
- **Bootstrap**: First-run deploys all content in `/infra` and `/apps`.
- **Interruption Protection**: The `.deploying` flag blocks new runs if the previous one crashed. Overridable with `FORCE_DEPLOY=1`.
- **Resource Checks**: Aborts if RAM < 1GB or Disk > 90% full.
- **Rollback**: Automatically checks out the previous successful state of a stack upon failure.
