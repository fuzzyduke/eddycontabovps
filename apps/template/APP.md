# App Manifest: {{APP_NAME}}

## 📋 Architectural Details
- **App Name**: {{APP_NAME}}
- **Domain**: {{SUBDOMAIN}}.valhallala.com
- **Internal Port**: {{INTERNAL_PORT}}
- **Docker Image**: {{IMAGE}}

## 🔒 Secrets
- **Bible Path**: `vps/{{APP_NAME}}.env`
- **VPS Runtime Path**: `/srv/secrets/{{APP_NAME}}.env`

## ✅ Verification
- **Endpoint**: `https://{{SUBDOMAIN}}.valhallala.com`
- **Healthy Status**: `200 OK`
- **Key Fingerprint**: Found in response headers
