#!/bin/bash
# Sync secrets from private Bible repo into /srv/secrets
# Requires SSH key for bible repo to be available

BIBLE_DIR="/opt/bible"
SECRETS_DIR="/srv/secrets"

echo "[$(date)] Starting secrets sync..."

# 1. Update/Clone Bible repo
if [ ! -d "$BIBLE_DIR/.git" ]; then
    echo "Cloning bible repository..."
    # Note: SSH URL should be used with BIBLE_REPO_SSH_KEY
    git clone git@github.com:fuzzyduke/bible.git "$BIBLE_DIR"
else
    echo "Updating bible repository..."
    cd "$BIBLE_DIR" && git pull origin master
fi

# 2. Sync secrets (Idempotent)
echo "Syncing env files..."
# Copy all .env files from the bible's 'vps' directory to /srv/secrets
# We assume the bible repo has a structure like:
# bible/
#   vps/
#     hello1.env
#     ...
if [ -d "$BIBLE_DIR/vps" ]; then
    cp -v "$BIBLE_DIR/vps"/*.env "$SECRETS_DIR/"
else
    echo "WARNING: $BIBLE_DIR/vps directory not found!"
fi

# 3. Secure permissions
echo "Securing permissions..."
chmod 700 "$SECRETS_DIR"
chmod 600 "$SECRETS_DIR"/*.env

echo "[$(date)] Sync complete."
