# SOP: New App Creation & Publishing

This document defines the deterministic pipeline for onboarding a new application to the Eddy VPS.

## 1. Required Inputs

Before starting, define these variables:
- **APP_NAME**: Unique lowercase identifier (e.g., `hello-world`).
- **SUBDOMAIN**: Subdomain for the app (e.g., `hello`).
- **DOMAIN**: Primary domain (usually `valhallala.com`).
- **INTERNAL_PORT**: The port the application listens on within the container (e.g., `80`, `3000`).
- **IMAGE**: Pinned Docker image tag (e.g., `nginx:1.27-alpine`). **DO NOT USE `latest`**.
- **RESOURCES**: Memory limit (e.g., `256m`) and CPU limit (e.g., `0.5`).
- **HEALTHCHECK**: Command to verify app health (e.g., `wget -qO- http://localhost:80`).

## 2. Step-by-Step Instructions

### Step A: Scaffolding
1. Run the scaffolding helper:
   ```bash
   ./scripts/new_app_scaffold.sh <APP_NAME> <SUBDOMAIN> <INTERNAL_PORT>
   ```
2. Verify the created files in `apps/<APP_NAME>/`.

### Step B: Service Configuration (`docker-compose.yml`)
Ensure the `apps/<APP_NAME>/docker-compose.yml` follows these hard constraints:
- **Network**: All apps MUST attach to the external `proxy` network.
- **Ports**: **DO NOT** expose host ports (`ports:` section should be commented out or removed).
- **Environment**: Point `env_file` to `/srv/secrets/<APP_NAME>.env`.
- **Labels (Traefik)**:
  - `traefik.enable=true`
  - `traefik.docker.network=proxy`
  - `traefik.http.routers.<APP_NAME>.rule=Host(\"<SUBDOMAIN>.<DOMAIN>\")`
  - `traefik.http.routers.<APP_NAME>.entrypoints=websecure`
  - `traefik.http.routers.<APP_NAME>.tls=true`
  - `traefik.http.routers.<APP_NAME>.tls.certresolver=letsencrypt`
  - `traefik.http.services.<APP_NAME>.loadbalancer.server.port=<INTERNAL_PORT>`

### Step C: Secrets Management (Private Bible)
1. Add `<APP_NAME>.env` to the `vps/` directory in the private **bible** repository.
2. Push changes to the bible repository.

### Step D: DNS Configuration (Cloudflare)
1. Create a CNAME or A record for `<SUBDOMAIN>` pointing to the VPS IP or root domain.
2. Ensure proxy status is enabled (orange cloud) if required.

### Step E: Publishing
1. Commit and push the public `eddycontabovps` repository:
   ```bash
   git add .
   git commit -m "feat: onboard <APP_NAME>"
   git push origin master
   ```
2. The GitHub Action will trigger, sync secrets from the Bible, and deploy the app.

## 3. Verification Commands

Run these on the VPS (or via SSH) to confirm success:
- **Container Health**: `docker compose -f /srv/apps/<APP_NAME>/docker-compose.yml ps`
- **Traefik Logs**: `docker logs traefik 2>&1 | grep <APP_NAME>`
- **Live Response**: `curl -f -I https://<SUBDOMAIN>.<DOMAIN>`
- **Content Check**: `curl -s https://<SUBDOMAIN>.<DOMAIN> | grep "expected text"`
