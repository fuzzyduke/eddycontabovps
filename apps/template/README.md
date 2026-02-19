# Mini-Dapp Template

Standardized boilerplate for deploying applications to the Eddy VPS using `deploy.sh v1.1.1`.

## 📂 Structure
- `docker-compose.yml`: Hardened service definition.
- `.env.example`: Template for environment variables.
- `upgrade.sh`: Idempotent upgrade logic (migrations, etc.).

## 🚀 How to Use

1. **Duplicate the Template**:
   ```bash
   cp -r apps/template apps/your-app-name
   cd apps/your-app-name
   ```

2. **Rename the Service**:
   Open `docker-compose.yml` and replace `app-name` with `your-app-name` in:
   - `services` key
   - `container_name`
   - `traefik` router/service labels
   - `volumes` (named volume)

3. **Set your Subdomain**:
   In `docker-compose.yml`, update the Traefik host rule label manually:
   `- "traefik.http.routers.your-app-name.rule=Host(\`your-subdomain.valhallala.com\`)"`


4. **Add Secrets**:
   - Rename `.env.example` to `.env`.
   - Add your environment variables (do not commit `.env` to Git).

5. **Customize Healthcheck**:
   Ensure the healthcheck `test` matches your application's internal health port/endpoint.

6. **Optional Upgrades**:
   Implement idempotent logic in `upgrade.sh`. To enable execution during deploy, ensure the script is executable and set `RUN_UPGRADES=1` in your environment or CI variables.

## 🚫 Critical Constraints
- **No Host Ports**: Never use the `ports:` keyword. Traefik routes traffic via labels.
- **No `latest` Tags**: Always pin your image tags (e.g., `nginx:1.27-bookworm`).
- **Network Isolation**: All apps must attach to the `proxy` external network.
- **Resource Limits**: Always maintain `mem_limit` and `cpus` to prevent VPS OOM events.

## 🔄 Rollback Readiness
This template is fully compatible with the `deploy.sh` rollback mechanism. If the healthcheck fails or `docker compose up` crashes, the engine will automatically revert this directory to its last known good commit.
