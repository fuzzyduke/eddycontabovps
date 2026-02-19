# Publish New App: Checklist

Use this checklist for every new application deployment. Reference [NEW_APP_SOP.md](NEW_APP_SOP.md) for detailed commands.

## 📋 App Definition
```text
APP_NAME=
SUBDOMAIN=
DOMAIN=valhallala.com
INTERNAL_PORT=
PUBLIC_URL=https://<SUBDOMAIN>.<DOMAIN>
SECRET_ENV_FILE=/srv/secrets/<APP_NAME>.env
```

## 🟩 Phase 1: Local Development
- [ ] Folder created: `apps/<APP_NAME>/`
- [ ] Docker image pinned (e.g., `image: name:1.2.3`)
- [ ] Resource limits set (`mem_limit`, `cpus`)
- [ ] Healthcheck implemented
- [ ] `env_file` points to `/srv/secrets/<APP_NAME>.env`
- [ ] Traefik labels correctly formatted with hardcoded Host rule
- [ ] `apps/<APP_NAME>/APP.md` manifest filled out

## 🟦 Phase 2: Secrets & DNS
- [ ] Secret file added to private **bible** repo: `vps/<APP_NAME>.env`
- [ ] Bible repo pushed to master
- [ ] Cloudflare DNS record created for `<SUBDOMAIN>`

## 🚀 Phase 3: Deployment
- [ ] `git push origin master` (eddycontabovps)
- [ ] GitHub Action "Deploy via SSH" completed successfully

## ✅ Definition of Done (DoD)
- [ ] `docker ps` show container is `Up (healthy)`
- [ ] `curl -I https://<SUBDOMAIN>.<DOMAIN>` returns `HTTP/2 200`
- [ ] TLS certificate is valid (issued by Let's Encrypt)
- [ ] Page content matches expectations
- [ ] `/srv/secrets/<APP_NAME>.env` exists on VPS with `600` permissions
