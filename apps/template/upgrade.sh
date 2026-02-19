#!/bin/bash
# /apps/template/upgrade.sh
# This script is called by deploy.sh if RUN_UPGRADES=1.
# It MUST be idempotent (safe to run multiple times).

set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] (UPGRADE) $1"
}

log "Starting upgrade stub for app-template..."

# --- IDEMPOTENT OPERATIONS ONLY ---
# Example: 
# - Database migrations (using a tool that tracks state)
# - Cache clearing
# - Directory permission fixes

# log "Clearing application cache..."
# rm -rf ./cache/* || true

log "Upgrade stub completed successfully."
exit 0
