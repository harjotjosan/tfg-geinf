#!/bin/bash
# Restoration script for DB Connectivity Error (Firewall)
# Run this on the DB VM (10.0.27.239)

echo "Restoring DB connectivity by removing iptables rules on port 5432..."

# 1. Remove rules from DOCKER-USER chain
if sudo iptables -L DOCKER-USER -n >/dev/null 2>&1; then
    echo "Removing rules from DOCKER-USER chain..."
    while sudo iptables -D DOCKER-USER -p tcp --dport 5432 -j DROP 2>/dev/null; do
        echo "Removed one DOCKER-USER block rule."
    done
fi

# 2. Remove rules from INPUT chain
echo "Removing rules from INPUT chain..."
while sudo iptables -D INPUT -p tcp --dport 5432 -j DROP 2>/dev/null; do
    echo "Removed one INPUT block rule."
done

echo "----------------------------------------------------"
echo "Iptables rules removed."
echo "Verify connectivity from Web VM (10.0.27.223) using: nc -zv 10.0.27.239 5432"
echo "The connection should now succeed."
