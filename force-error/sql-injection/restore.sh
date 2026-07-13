#!/bin/bash
# Restoration script for SQL Injection (Loki 4)
# Run this on the Web VM (10.0.27.223)

CONTAINER_NAME="carparts-web"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/../../pve1/vm-web/docker-compose.yml"

echo "Remediating SQL Injection vulnerability by setting SQL_INJECTION_VULNERABLE=false..."

# Update SQL_INJECTION_VULNERABLE to false if present
if grep -q "SQL_INJECTION_VULNERABLE" "$COMPOSE_FILE"; then
    echo "Updating SQL_INJECTION_VULNERABLE to false..."
    sed -i 's/SQL_INJECTION_VULNERABLE:.*/SQL_INJECTION_VULNERABLE: "false"/' "$COMPOSE_FILE"
else
    echo "SQL_INJECTION_VULNERABLE not found. Making sure it is set to false..."
    sed -i '/DB_PASSWORD: carparts_pass/a \      SQL_INJECTION_VULNERABLE: "false"' "$COMPOSE_FILE"
fi

# Rebuild/Restart the container
echo "Rebuilding and restarting web container with vulnerability disabled..."
cd "$SCRIPT_DIR/../../pve1/vm-web"
docker compose up -d --build

# Wait for container to start
echo "Waiting 5 seconds for Flask app to start..."
sleep 5

echo "----------------------------------------------------"
echo "SQL Injection vulnerability successfully disabled."
echo "Secure parameterized query execution is active."
