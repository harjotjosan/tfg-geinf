#!/bin/bash
# Programmatic Verification Script for Certificate Expiry Scenario
# Run this on the Proxy VM (10.0.27.228)

set -euo pipefail

# Determine script directory for relative path referencing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="$SCRIPT_DIR/../../pve1/vm-proxy/certs"
CONTAINER_NAME="carparts-proxy"

echo "=== GEMRAT Certificate Expiry Verification Script ==="

# Helper: Wait for Nginx to be ready on port 443
wait_for_nginx() {
    local max_attempts=5
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        # Use bash dev/tcp if possible, otherwise nc or openssl
        if bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/443' >/dev/null 2>&1; then
            return 0
        elif command -v nc &>/dev/null && nc -z 127.0.0.1 443 >/dev/null 2>&1; then
            return 0
        elif command -v openssl &>/dev/null && openssl s_client -connect 127.0.0.1:443 -servername localhost </dev/null >/dev/null 2>&1; then
            return 0
        fi
        echo "Waiting for port 443 to be ready (attempt $attempt/$max_attempts)..."
        sleep 1
        attempt=$((attempt + 1))
    done
    return 1
}

# Helper: Verify if served certificate is expired
# Returns 0 if valid (not expired), 1 if expired, 99 on connection failure
check_cert_expired() {
    local cert_data
    # Use -connect 127.0.0.1:443 and specify localhost for SNI
    cert_data=$(openssl s_client -connect 127.0.0.1:443 -servername localhost </dev/null 2>/dev/null) || true
    if [ -z "$cert_data" ] || ! echo "$cert_data" | grep -q "-----BEGIN CERTIFICATE-----"; then
        echo "Error: Failed to retrieve a valid certificate block from 127.0.0.1:443"
        return 99
    fi
    
    if echo "$cert_data" | openssl x509 -noout -checkend 0 >/dev/null 2>&1; then
        return 0 # Valid (not expired)
    else
        return 1 # Expired
    fi
}

# Helper: Print served cert details
print_cert_details() {
    openssl s_client -connect 127.0.0.1:443 -servername localhost </dev/null 2>/dev/null | \
        openssl x509 -noout -subject -dates || echo "Failed to retrieve cert details."
}

# Helper: Check container is running
check_container_running() {
    local status
    status=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null || echo "false")
    if [ "$status" != "true" ]; then
        echo "Error: Docker container $CONTAINER_NAME is not running."
        exit 1
    fi
}

# Ensure openssl is installed
if ! command -v openssl &>/dev/null; then
    echo "Error: openssl command not found."
    exit 1
fi

# ==========================================
# STEP 1: Verify Baseline State
# ==========================================
echo -e "\n--- Step 1: Initializing and Verifying Baseline State ---"
"$SCRIPT_DIR/restore.sh"
sleep 2
check_container_running
wait_for_nginx

echo "Served certificate in Baseline state:"
print_cert_details

cert_status=0
check_cert_expired || cert_status=$?

if [ "$cert_status" -eq 0 ]; then
    echo "SUCCESS: Baseline served certificate is VALID."
elif [ "$cert_status" -eq 99 ]; then
    echo "FAIL: Failed to connect to Nginx server on port 443!"
    exit 1
else
    echo "FAIL: Baseline served certificate is EXPIRED!"
    exit 1
fi

# Verify both certs are present
if [ -f "$CERTS_DIR/valid.crt" ] && [ -f "$CERTS_DIR/expired.crt" ]; then
    echo "SUCCESS: Both valid.crt and expired.crt exist in $CERTS_DIR."
else
    echo "FAIL: Missing certificates in $CERTS_DIR."
    exit 1
fi

# ==========================================
# STEP 2: Verify Scenario A (Expired cert served, valid cert exists)
# ==========================================
echo -e "\n--- Step 2: Triggering and Verifying Scenario A ---"
"$SCRIPT_DIR/provoke.sh" A
sleep 2
check_container_running
wait_for_nginx

echo "Served certificate in Scenario A state:"
print_cert_details

cert_status=0
check_cert_expired || cert_status=$?

if [ "$cert_status" -eq 1 ]; then
    echo "SUCCESS: Scenario A served certificate is EXPIRED."
elif [ "$cert_status" -eq 99 ]; then
    echo "FAIL: Failed to connect to Nginx server on port 443!"
    exit 1
else
    echo "FAIL: Scenario A served certificate is VALID!"
    exit 1
fi

# Verify valid.crt still exists
if [ -f "$CERTS_DIR/valid.crt" ]; then
    echo "SUCCESS: valid.crt remains in $CERTS_DIR."
else
    echo "FAIL: valid.crt was deleted/renamed in Scenario A!"
    exit 1
fi

# ==========================================
# STEP 3: Verify Scenario B (Expired cert served, valid cert renamed/deleted)
# ==========================================
echo -e "\n--- Step 3: Triggering and Verifying Scenario B ---"
"$SCRIPT_DIR/provoke.sh" B
sleep 2
check_container_running
wait_for_nginx

echo "Served certificate in Scenario B state:"
print_cert_details

cert_status=0
check_cert_expired || cert_status=$?

if [ "$cert_status" -eq 1 ]; then
    echo "SUCCESS: Scenario B served certificate is EXPIRED."
elif [ "$cert_status" -eq 99 ]; then
    echo "FAIL: Failed to connect to Nginx server on port 443!"
    exit 1
else
    echo "FAIL: Scenario B served certificate is VALID!"
    exit 1
fi

# Verify valid.crt is renamed/deleted
if [ ! -f "$CERTS_DIR/valid.crt" ]; then
    echo "SUCCESS: valid.crt does not exist (renamed/deleted as expected)."
else
    echo "FAIL: valid.crt still exists in $CERTS_DIR under Scenario B!"
    exit 1
fi

# ==========================================
# STEP 4: Verify Restored State
# ==========================================
echo -e "\n--- Step 4: Reverting and Verifying Restored State ---"
"$SCRIPT_DIR/restore.sh"
sleep 2
check_container_running
wait_for_nginx

echo "Served certificate in Restored state:"
print_cert_details

cert_status=0
check_cert_expired || cert_status=$?

if [ "$cert_status" -eq 0 ]; then
    echo "SUCCESS: Restored served certificate is VALID."
elif [ "$cert_status" -eq 99 ]; then
    echo "FAIL: Failed to connect to Nginx server on port 443!"
    exit 1
else
    echo "FAIL: Restored served certificate is EXPIRED!"
    exit 1
fi

# Verify valid.crt is restored
if [ -f "$CERTS_DIR/valid.crt" ]; then
    echo "SUCCESS: valid.crt has been restored in $CERTS_DIR."
else
    echo "FAIL: valid.crt is missing after restore!"
    exit 1
fi

echo -e "\n=== ALL TRANSITION CHECKS PASSED SUCCESSFULLY ==="
exit 0
