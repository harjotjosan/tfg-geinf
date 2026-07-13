#!/bin/bash
# Restoration script for Certificate Expiry Scenario (DOCKER VERSION)
# Run this on the Proxy VM (10.0.27.228)

set -euo pipefail

CONTAINER_NAME="carparts-proxy"

# Check if container is running
if ! docker inspect --format="{{.State.Running}}" "$CONTAINER_NAME" 2>/dev/null | grep -q "true"; then
    echo "Error: Container '$CONTAINER_NAME' is not running or does not exist." >&2
    exit 1
fi

echo "Restoring Certificate Expiry Scenario in container: $CONTAINER_NAME..."

# 1. Determine directories relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_CERTS_DIR="$SCRIPT_DIR/../../pve1/vm-proxy/certs"
SOURCE_CERTS_DIR="$SCRIPT_DIR/certs"

# 2. Restore certificate files on the host if they were renamed (Scenario B)
if [ -f "$HOST_CERTS_DIR/valid.crt.bak" ]; then
    echo "Restoring valid certificate file on host from backup..."
    mv "$HOST_CERTS_DIR/valid.crt.bak" "$HOST_CERTS_DIR/valid.crt"
fi
if [ -f "$HOST_CERTS_DIR/valid.key.bak" ]; then
    echo "Restoring valid certificate key file on host from backup..."
    mv "$HOST_CERTS_DIR/valid.key.bak" "$HOST_CERTS_DIR/valid.key"
fi

# Ensure valid.crt/key exist. If they still don't exist, copy them from source directory
if [ ! -f "$HOST_CERTS_DIR/valid.crt" ]; then
    echo "Copying valid certificate from source directory..."
    cp "$SOURCE_CERTS_DIR/valid.crt" "$HOST_CERTS_DIR/valid.crt"
fi
if [ ! -f "$HOST_CERTS_DIR/valid.key" ]; then
    echo "Copying valid key from source directory..."
    cp "$SOURCE_CERTS_DIR/valid.key" "$HOST_CERTS_DIR/valid.key"
fi

# 3. Restore Nginx config from backup inside the container, or fall back to repository version
TMP_BAK=$(mktemp /tmp/nginx.conf.bak.XXXXXX)

if docker cp "$CONTAINER_NAME:/etc/nginx/nginx.conf.bak" "$TMP_BAK" 2>/dev/null; then
    echo "Found backup file inside container. Restoring config..."
    docker cp "$TMP_BAK" "$CONTAINER_NAME:/etc/nginx/nginx.conf"
    rm -f "$TMP_BAK"
else
    rm -f "$TMP_BAK"
    echo "No backup found inside container. Attempting fallback to repository configuration..."
    REPO_CONF="$SCRIPT_DIR/../../pve1/proxy/nginx.conf"
    if [ -f "$REPO_CONF" ]; then
        docker cp "$REPO_CONF" "$CONTAINER_NAME:/etc/nginx/nginx.conf"
    else
        echo "Warning: Fallback configuration not found at $REPO_CONF. Reverting config using sed..."
        docker exec "$CONTAINER_NAME" sed -i 's/expired.crt/valid.crt/g' /etc/nginx/nginx.conf
        docker exec "$CONTAINER_NAME" sed -i 's/expired.key/valid.key/g' /etc/nginx/nginx.conf
    fi
fi

# 4. Safe Reload
echo "Checking Nginx configuration syntax..."
if docker exec "$CONTAINER_NAME" nginx -t; then
    echo "Syntax check passed. Reloading Nginx..."
    docker exec "$CONTAINER_NAME" nginx -s reload
    echo "Restoration complete. Nginx is serving the valid certificate."
    echo "Removing backup config inside container..."
    docker exec "$CONTAINER_NAME" rm -f /etc/nginx/nginx.conf.bak
else
    echo "Warning: Initial Nginx configuration check failed! Attempting fallback to repository configuration..."
    REPO_CONF="$SCRIPT_DIR/../../pve1/proxy/nginx.conf"
    if [ -f "$REPO_CONF" ]; then
        echo "Copying repository configuration fallback ($REPO_CONF) to container..."
        docker cp "$REPO_CONF" "$CONTAINER_NAME:/etc/nginx/nginx.conf"
        echo "Re-checking Nginx configuration syntax with fallback..."
        if docker exec "$CONTAINER_NAME" nginx -t; then
            echo "Fallback configuration syntax check passed. Reloading Nginx..."
            docker exec "$CONTAINER_NAME" nginx -s reload
            echo "Restoration complete using fallback configuration. Nginx is serving the valid certificate."
            echo "Removing backup config inside container..."
            docker exec "$CONTAINER_NAME" rm -f /etc/nginx/nginx.conf.bak
        else
            echo "Warning: Fallback configuration syntax check failed! Restarting container as a last resort..."
            docker restart "$CONTAINER_NAME"
            echo "Removing backup config inside container..."
            docker exec "$CONTAINER_NAME" rm -f /etc/nginx/nginx.conf.bak || true
        fi
    else
        echo "Warning: Fallback configuration file not found at $REPO_CONF! Restarting container as a last resort..."
        docker restart "$CONTAINER_NAME"
        echo "Removing backup config inside container..."
        docker exec "$CONTAINER_NAME" rm -f /etc/nginx/nginx.conf.bak || true
    fi
fi
