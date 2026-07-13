#!/bin/bash
# Restoration script for Nginx Syntax Error (DOCKER VERSION)
# Run this on the Proxy VM (10.0.27.228)

CONTAINER_NAME="carparts-proxy"

echo "Restoring Nginx configuration in container: $CONTAINER_NAME..."

# Create a temporary file on the host to attempt extracting the backup via docker cp
# docker cp works even if the container is stopped or in a restart loop.
TMP_BAK=$(mktemp /tmp/nginx.conf.bak.XXXXXX)

if docker cp "$CONTAINER_NAME:/etc/nginx/nginx.conf.bak" "$TMP_BAK" 2>/dev/null; then
    echo "Found backup file inside container using docker cp. Restoring..."
    docker cp "$TMP_BAK" "$CONTAINER_NAME:/etc/nginx/nginx.conf"
    rm -f "$TMP_BAK"
    
    echo "Restarting container to apply restored configuration..."
    docker restart "$CONTAINER_NAME"
    echo "Nginx configuration successfully restored from backup."
else
    rm -f "$TMP_BAK"
    echo "Backup file not found inside container via docker cp."
    
    # Fallback: Check if there's an original nginx.conf in the repo we can use
    SCRIPT_DIR="$(dirname "$0")"
    REPO_CONF="$SCRIPT_DIR/../../pve1/proxy/nginx.conf"
    
    if [ -f "$REPO_CONF" ]; then
        echo "Found original configuration in repository at $REPO_CONF. Restoring from fallback..."
        docker cp "$REPO_CONF" "$CONTAINER_NAME:/etc/nginx/nginx.conf"
        echo "Restarting container..."
        docker restart "$CONTAINER_NAME"
        echo "Nginx configuration successfully restored from repository fallback."
    else
        echo "Error: Could not recover Nginx configuration! No backup found inside container and repository fallback not found."
        exit 1
    fi
fi
