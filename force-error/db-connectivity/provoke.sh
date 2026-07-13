#!/bin/bash
# Provocation script for DB Connectivity Error (Firewall)
# Run this on the DB VM (10.0.27.239)

echo "Provoking DB connectivity error by blocking port 5432 via iptables..."

# 1. Block port 5432 in DOCKER-USER chain (for dockerized PostgreSQL)
if sudo iptables -L DOCKER-USER -n >/dev/null 2>&1; then
    echo "Adding rule to DOCKER-USER chain..."
    # Insert at the beginning of DOCKER-USER chain to override other docker rules
    sudo iptables -I DOCKER-USER -p tcp --dport 5432 -j DROP
else
    echo "DOCKER-USER chain not found (Docker might not be running or iptables not configured for it)."
fi

# 2. Block port 5432 in INPUT chain (for host-native PostgreSQL, if any)
echo "Adding rule to INPUT chain..."
sudo iptables -I INPUT -p tcp --dport 5432 -j DROP

echo "----------------------------------------------------"
echo "Port 5432 blocked via iptables."
echo "Verify connectivity from Web VM (10.0.27.223) using: nc -zv 10.0.27.239 5432"
echo "The connection should TIMEOUT."
