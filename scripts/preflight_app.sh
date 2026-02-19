#!/bin/bash
set -euo pipefail

# Hardened Preflight script to validate app configuration before pushing
# Usage: ./scripts/preflight_app.sh <APP_NAME>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <APP_NAME>"
    exit 1
fi

APP_NAME=$1
COMPOSE_FILE="apps/$APP_NAME/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Error: $COMPOSE_FILE not found."
    exit 1
fi

echo "🔍 Running hardened preflight for $APP_NAME..."
ERRORS=()

# 1. Check for host port exposure (Strict detection)
# Matches "^ +ports:" (uncommented block)
if grep -E "^ +ports:" "$COMPOSE_FILE" > /dev/null; then
    ERRORS+=("Host port exposure ('ports:') detected. Host ports are forbidden.")
fi

# 2. Check for latest image tag
if grep -q "image:.*latest" "$COMPOSE_FILE"; then
    ERRORS+=("'latest' tag detected in image. Please use a pinned version.")
fi

# 3. Check for resource limits
if ! grep -q "mem_limit:" "$COMPOSE_FILE"; then
    ERRORS+=("'mem_limit' is missing.")
fi
if ! grep -q "cpus:" "$COMPOSE_FILE"; then
    ERRORS+=("'cpus' limit is missing.")
fi

# 4. Check for healthcheck
if ! grep -q "healthcheck:" "$COMPOSE_FILE"; then
    ERRORS+=("'healthcheck' section is missing.")
fi

# 5. Check for correct env_file path
EXPECTED_ENV="/srv/secrets/$APP_NAME.env"
if ! grep -q "env_file: $EXPECTED_ENV" "$COMPOSE_FILE"; then
    ERRORS+=("'env_file' must be exactly $EXPECTED_ENV")
fi

# 6. Check for Traefik backtick rule (Robust validation)
# Ensures exact router name and backticked Host rule
if ! grep -F "traefik.http.routers.$APP_NAME.rule=Host(\`" "$COMPOSE_FILE" > /dev/null; then
    ERRORS+=("Traefik rule for $APP_NAME is missing or incorrectly formatted. Must use Host(\`...\`) with backticks.")
fi

# 7. Check for proxy network attachment (Two-tiered)
# a) Service-level attachment
if ! grep -E "^ +networks:" -A 5 "$COMPOSE_FILE" | grep -q "\- proxy"; then
    ERRORS+=("Service is not attached to the 'proxy' network.")
fi
# b) Top-level external declaration
if ! grep -A 5 "^networks:" "$COMPOSE_FILE" | grep -A 2 "proxy:" | grep -q "external: true"; then
    ERRORS+=("Top-level 'proxy' network must be declared as 'external: true'.")
fi

# 8. docker compose config check
echo "⏳ Validating YAML syntax..."
if ! docker compose -f "$COMPOSE_FILE" config > /dev/null 2>&1; then
    ERRORS+=("'docker compose config' failed. Check YAML indentation.")
fi

# Final Report
if [ ${#ERRORS[@]} -eq 0 ]; then
    echo "✅ Preflight PASSED for $APP_NAME."
    exit 0
else
    echo "------------------------------------------------------------"
    echo "❌ Preflight FAILED for $APP_NAME with ${#ERRORS[@]} error(s):"
    for err in "${ERRORS[@]}"; do
        echo "  - $err"
    done
    echo "------------------------------------------------------------"
    echo "Please fix the above errors before pushing."
    exit 1
fi
