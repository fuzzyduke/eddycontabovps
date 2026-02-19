#!/bin/bash
# Scaffolding helper for new Eddy VPS apps
# Usage: ./scripts/new_app_scaffold.sh <APP_NAME> <SUBDOMAIN> <INTERNAL_PORT>

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <APP_NAME> <SUBDOMAIN> <INTERNAL_PORT>"
    exit 1
fi

APP_NAME=$1
SUBDOMAIN=$2
INTERNAL_PORT=$3
TEMPLATE_DIR="apps/template"
TARGET_DIR="apps/$APP_NAME"

if [ -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR already exists."
    exit 1
fi

echo "Scaffolding new app: $APP_NAME..."

# 1. Copy template
cp -r "$TEMPLATE_DIR" "$TARGET_DIR"

# 2. Replace placeholders in docker-compose.yml
# Note: We use a simple sed replacement. For more complex cases, a proper template engine is better.
sed -i "s/template-service/$APP_NAME-service/g" "$TARGET_DIR/docker-compose.yml"
sed -i "s/Host(\`template.valhallala.com\`)/Host(\`$SUBDOMAIN.valhallala.com\`)/g" "$TARGET_DIR/docker-compose.yml"
sed -i "s/loadbalancer.server.port=80/loadbalancer.server.port=$INTERNAL_PORT/g" "$TARGET_DIR/docker-compose.yml"
sed -i "s/env_file: .env/env_file: \/srv\/secrets\/$APP_NAME.env/g" "$TARGET_DIR/docker-compose.yml"

# 3. Create APP.md from template
sed -i "s/{{APP_NAME}}/$APP_NAME/g" "$TARGET_DIR/APP.md"
sed -i "s/{{SUBDOMAIN}}/$SUBDOMAIN/g" "$TARGET_DIR/APP.md"
sed -i "s/{{INTERNAL_PORT}}/$INTERNAL_PORT/g" "$TARGET_DIR/APP.md"

# 4. Cleanup/Rename README if necessary
mv "$TARGET_DIR/README.md" "$TARGET_DIR/ARCH_NOTES.md"

echo "Done! Scaffolding complete in $TARGET_DIR."
echo "Next steps: Edit $TARGET_DIR/docker-compose.yml to pin your image and add secrets to the Bible repo."
