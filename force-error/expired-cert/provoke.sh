#!/bin/bash
# Provocation script for Certificate Expiry Scenario (DOCKER VERSION)
# Run this on the Proxy VM (10.0.27.228)

set -euo pipefail

SCENARIO="${1:-}"
CONTAINER_NAME="carparts-proxy"

if [[ "$SCENARIO" != "A" && "$SCENARIO" != "B" ]]; then
    echo "Usage: $0 [A|B]"
    exit 1
fi

# Check if container is running
if ! docker inspect --format="{{.State.Running}}" "$CONTAINER_NAME" 2>/dev/null | grep -q "true"; then
    echo "Error: Container '$CONTAINER_NAME' is not running or does not exist." >&2
    exit 1
fi

echo "Provoking Certificate Expiry Scenario $SCENARIO in container: $CONTAINER_NAME..."

# 1. Determine directories relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_CERTS_DIR="$SCRIPT_DIR/../../pve1/vm-proxy/certs"

# 2. Create a backup of nginx.conf inside the container if it doesn't exist
if ! docker exec "$CONTAINER_NAME" test -f /etc/nginx/nginx.conf.bak; then
    docker exec "$CONTAINER_NAME" cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
fi

# 3. Modify nginx.conf inside the container to point to the expired certs
# Ensure we start from clean backup if it exists to avoid nested edits
docker exec "$CONTAINER_NAME" cp /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
docker exec "$CONTAINER_NAME" sed -i 's/valid.crt/expired.crt/g' /etc/nginx/nginx.conf
docker exec "$CONTAINER_NAME" sed -i 's/valid.key/expired.key/g' /etc/nginx/nginx.conf

# 4. Handle Scenario Specifics
if [ "$SCENARIO" = "A" ]; then
    echo "Scenario A: Ensuring valid certificate remains available in the mounted directory..."
    # If previously renamed by Scenario B, restore it
    if [ -f "$HOST_CERTS_DIR/valid.crt.bak" ]; then
        mv "$HOST_CERTS_DIR/valid.crt.bak" "$HOST_CERTS_DIR/valid.crt"
    fi
    if [ -f "$HOST_CERTS_DIR/valid.key.bak" ]; then
        mv "$HOST_CERTS_DIR/valid.key.bak" "$HOST_CERTS_DIR/valid.key"
    fi
elif [ "$SCENARIO" = "B" ]; then
    echo "Scenario B: Renaming valid certificate on host to make it unavailable..."
    if [ -f "$HOST_CERTS_DIR/valid.crt" ]; then
        mv "$HOST_CERTS_DIR/valid.crt" "$HOST_CERTS_DIR/valid.crt.bak"
    fi
    if [ -f "$HOST_CERTS_DIR/valid.key" ]; then
        mv "$HOST_CERTS_DIR/valid.key" "$HOST_CERTS_DIR/valid.key.bak"
    fi
fi

# 5. Reload Nginx
echo "Checking Nginx configuration syntax..."
if docker exec "$CONTAINER_NAME" nginx -t; then
    echo "Syntax check passed. Reloading Nginx..."
    docker exec "$CONTAINER_NAME" nginx -s reload
    echo "Nginx successfully reloaded. Serving expired certificate."
else
    echo "Error: Nginx configuration check failed!"
    exit 1
fi
