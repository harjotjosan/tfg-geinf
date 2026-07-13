# Scenario 05: Certificate Expiry (Mock)

## Description
This test scenario simulates certificate expiration on the reverse proxy VM (`carparts-proxy`). It supports testing automated diagnosis and recovery procedures by simulating two kinds of certificate failures:
1. **Scenario A**: The proxy configuration points to an expired certificate, but the valid certificate is still present in the volume. This represents a configuration mistake where Nginx was pointed to the wrong file.
2. **Scenario B**: The proxy configuration points to an expired certificate, and the valid certificate is missing or renamed in the certificates directory. This represents a scenario where the valid certificate has been lost or deleted.

## Target
- **VM:** Proxy VM (10.0.27.228)
- **Service:** Nginx (`carparts-proxy` container)
- **Files Affected:** 
  - Nginx Configuration: `/etc/nginx/nginx.conf`
  - Active Certificates Volume (Host): `pve1/vm-proxy/certs/` (mounted to `/etc/nginx/certs` in container)

## Files
- `provoke.sh`: Automates triggering of certificate errors.
  - Usage: `./provoke.sh A` (Scenario A) or `./provoke.sh B` (Scenario B)
- `restore.sh`: Restores baseline Nginx configuration and certificate files.
  - Usage: `./restore.sh`
- `verify.sh`: Programmatic validation script verifying state transitions.
  - Usage: `./verify.sh`
- `certs/`: Pre-generated self-signed certificates:
  - `valid.crt` / `valid.key` (valid for 365 days)
  - `expired.crt` / `expired.key` (expired certificate)

## State Transition Matrix & Expected Behavior

| State | Served Certificate Status | Host `certs/valid.crt` Status | Description |
|---|---|---|---|
| **Baseline** | VALID | Present | Normal HTTPS operation. |
| **Scenario A** | EXPIRED | Present | Wrong certificate file referenced in `nginx.conf`. |
| **Scenario B** | EXPIRED | Renamed / Absent | Wrong certificate file referenced AND valid cert file deleted or renamed. |
| **Restored** | VALID | Present | Configuration reverted, cert files restored. |

---

## Prerequisites
Before running the scripts, make sure they are executable:
```bash
chmod +x provoke.sh restore.sh verify.sh
```

## Manual Step-by-Step Operations

### 1. Baseline State
Normally, the system runs with the valid self-signed certificate.
```bash
./restore.sh
```
Verify status:
- Port 443 is open.
- Checking validity returns `Certificate will not expire`:
  ```bash
  openssl s_client -connect localhost:443 -servername localhost </dev/null 2>/dev/null | openssl x509 -noout -checkend 0
  ```

### 2. Triggering Scenario A
Injects the wrong certificate reference in Nginx while keeping the valid file:
```bash
./provoke.sh A
```
Validation:
- Served certificate is expired (`openssl ... -checkend 0` fails).
- The file `pve1/vm-proxy/certs/valid.crt` still exists.

### 3. Triggering Scenario B
Injects the wrong certificate reference and renames the valid certificate file:
```bash
./provoke.sh B
```
Validation:
- Served certificate is expired.
- The file `pve1/vm-proxy/certs/valid.crt` is renamed to `valid.crt.bak` (absent).

### 4. Running Programmatic Verification
To automatically run the entire lifecycle test suite and confirm transition correctness:
```bash
./verify.sh
```
Expected output: Returns exit code `0` and prints validation steps showing all checks passed.
