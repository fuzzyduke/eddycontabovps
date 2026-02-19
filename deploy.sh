#!/bin/bash
# /srv/deploy.sh - Production-Hardened Deployment Engine for Eddy VPS
# Patched version: v1.1.1

set -euo pipefail
IFS=$'\n\t'

# Configuration
REPO_DIR="/srv"
APPS_DIR="${REPO_DIR}/apps"
INFRA_DIR="${REPO_DIR}/infra"
LOG_DIR="/var/log/deployments"
DEPLOYING_FLAG="${REPO_DIR}/.deploying"
LAST_SUCCESS_FILE="${LOG_DIR}/.last_deployed_commit"
MAX_HEALTH_WAIT=60 

# Environment Flags (Default to safe/off)
RUN_UPGRADES=${RUN_UPGRADES:-0}
FORCE_DEPLOY=${FORCE_DEPLOY:-0}
ALLOW_NO_HEALTHCHECK=${ALLOW_NO_HEALTHCHECK:-0}

# Ensure log directory exists
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_DIR}/global.log"
}

error() {
    log "ERROR: $1"
    exit 1
}

# 1. Concurrency & Interruption Locking
LOCKFILE="/tmp/eddy-deploy.lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    log "Deployment already in progress. Aborting."
    exit 0
fi

# 2. .deploying Flag Protection (Patch 2)
if [ -f "$DEPLOYING_FLAG" ]; then
    if [ "$FORCE_DEPLOY" -eq 1 ]; then
        log "WARNING: Previous deploy flag exists, but FORCE_DEPLOY=1. Proceeding..."
    else
        log "CRITICAL: Previous deployment was interrupted or failed (.deploying flag exists)."
        log "To override, set FORCE_DEPLOY=1."
        exit 1
    fi
fi

# 3. Drift Protection
cd "$REPO_DIR"
if [[ -n $(git status --porcelain) ]]; then
    log "Uncommitted local changes detected on VPS."
    git status --porcelain
    error "Refusing deployment due to infrastructure drift. Local state must match Git HEAD."
fi

# Create deployment flag
touch "$DEPLOYING_FLAG"

# 4. Bootstrap Logic (Patch 1)
BOOTSTRAP=0
TARGET_COMMIT=$(git rev-parse --short HEAD)

if [ ! -f "$LAST_SUCCESS_FILE" ] || [ ! -s "$LAST_SUCCESS_FILE" ]; then
    log "BOOTSTRAP MODE: No previous successful deployment found."
    BOOTSTRAP=1
    # Discover all apps and infra
    CHANGED_DIRS=$(find apps infra -maxdepth 1 -mindepth 1 -type d)
else
    LAST_SUCCESS_COMMIT=$(cat "$LAST_SUCCESS_FILE")
    log "Detecting changes since $LAST_SUCCESS_COMMIT..."
    CHANGED_DIRS=$(git diff --name-only "$LAST_SUCCESS_COMMIT" HEAD | cut -d/ -f1,2 | sort -u || true)
fi

log "Target Commit: $TARGET_COMMIT"

# 5. Resource Pre-checks
check_resources() {
    log "Validating system resources..."
    local FREE_MEM=$(awk '/MemAvailable/ {print $2}' /proc/meminfo) # in kB
    if [ "$FREE_MEM" -lt 1048576 ]; then
        error "Insufficient RAM: $((FREE_MEM / 1024))MB available. Need > 1024MB."
    fi
    local DISK_USAGE=$(df / --output=pcent | tail -1 | tr -dc '0-9')
    if [ "$DISK_USAGE" -gt 90 ]; then
        error "Insufficient Disk Space: ${DISK_USAGE}% used. Need > 10% free."
    fi

    # Swap Check (%)
    local SWAP_TOTAL=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        local SWAP_FREE=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
        local SWAP_USED_PCT=$(( (SWAP_TOTAL - SWAP_FREE) * 100 / SWAP_TOTAL ))
        if [ "$SWAP_USED_PCT" -gt 70 ]; then
            error "High Swap Usage: ${SWAP_USED_PCT}%. Potential OOM risk."
        fi
        log "Swap usage: ${SWAP_USED_PCT}%."
    fi
    log "Resource check passed."
}
check_resources

# 6. Safety Scanner & Stack Deployment
scan_upgrade_script() {
    local SCRIPT=$1
    local BLACKLIST=("docker system prune" "docker volume rm" "docker network rm" "rm -rf /")
    for pattern in "${BLACKLIST[@]}"; do
        if grep -Fq "$pattern" "$SCRIPT"; then
            error "Safety Violation: Unsafe command '$pattern' detected in $SCRIPT"
        fi
    done
}

verify_health() {
    local STACK_NAME=$1
    local START_TIME=$(date +%s)
    
    while [ $(($(date +%s) - START_TIME)) -lt $MAX_HEALTH_WAIT ]; do
        local STATUS=$(docker compose ps --format json)
        local ALL_HEALTHY=1
        
        # Parse each container
        while read -r container; do
            local NAME=$(echo "$container" | jq -r '.Name')
            local STATE=$(echo "$container" | jq -r '.State')
            local HEALTH=$(echo "$container" | jq -r '.Health // "none"')
            
            if [[ "$STATE" != "running" ]]; then
                ALL_HEALTHY=0; break
            fi
            
            if [[ "$HEALTH" == "unhealthy" ]] || [[ "$HEALTH" == "starting" ]]; then
                ALL_HEALTHY=0; break
            fi
            
            if [[ "$HEALTH" == "none" ]] && [[ "$ALLOW_NO_HEALTHCHECK" -eq 0 ]]; then
                # Check for restart count as fallback
                local RESTARTS=$(docker inspect "$NAME" --format '{{.RestartCount}}')
                if [ "$RESTARTS" -gt 0 ]; then
                    ALL_HEALTHY=0; break
                fi
            fi
        done < <(echo "$STATUS" | jq -c '.[]')

        if [ "$ALL_HEALTHY" -eq 1 ]; then
            log "Success: $STACK_NAME is healthy."
            return 0
        fi
        sleep 5
    done
    return 1
}

rollback_stack() {
    local STACK_DIR=$1
    local STACK_NAME=$(basename "$STACK_DIR")
    if [ "$BOOTSTRAP" -eq 1 ]; then
        error "Deployment failed during bootstrap for $STACK_NAME. No rollback commit available."
    fi

    log "CRITICAL: Rollback triggered for $STACK_NAME..."
    cd "$REPO_DIR"
    git checkout "$LAST_SUCCESS_COMMIT" -- "$STACK_DIR"
    
    cd "$STACK_DIR"
    docker compose pull
    docker compose up -d --remove-orphans
    
    if verify_health "$STACK_NAME"; then
        log "Rollback successful for $STACK_NAME."
        error "Stack $STACK_NAME failed deploy and was rolled back to known-good state."
    else
        log "FATAL: Rollback failed for $STACK_NAME. Manual intervention required."
        exit 1 # Keep .deploying flag
    fi
}

deploy_stack() {
    local STACK_DIR=$1
    local STACK_NAME=$(basename "$STACK_DIR")
    local APP_LOG="${LOG_DIR}/${STACK_NAME}.log"

    log "Deploying stack: $STACK_NAME..."
    cd "$STACK_DIR"
    
    docker compose config > /dev/null 2>&1 || rollback_stack "$STACK_DIR"

    # Opt-in Upgrades (Patch 5)
    if [ -x "upgrade.sh" ]; then
        if [ "$RUN_UPGRADES" -eq 1 ]; then
            scan_upgrade_script "upgrade.sh"
            ./upgrade.sh >> "$APP_LOG" 2>&1 || rollback_stack "$STACK_DIR"
        else
            log "Upgrade script found but skipped (RUN_UPGRADES=0)."
        fi
    fi

    docker compose pull >> "$APP_LOG" 2>&1 || rollback_stack "$STACK_DIR"
    docker compose up -d --remove-orphans >> "$APP_LOG" 2>&1 || rollback_stack "$STACK_DIR"

    verify_health "$STACK_NAME" || rollback_stack "$STACK_DIR"
}

# 7. Execution Loop
for DIR in $CHANGED_DIRS; do
    if [ -d "${REPO_DIR}/${DIR}" ] && [ -f "${REPO_DIR}/${DIR}/docker-compose.yml" ]; then
        deploy_stack "${REPO_DIR}/${DIR}"
    fi
done

# 8. Success Cleanup
rm -f "$DEPLOYING_FLAG"
echo "$TARGET_COMMIT" > "$LAST_SUCCESS_FILE"
docker image prune -f --filter "until=24h"
log "Deployment successful: Commit $TARGET_COMMIT"
