# GEMRAT Demonstration Scenarios

This folder contains scripts and guides to manually provoke errors in the 3-tier infrastructure to test the GEMRAT automated recovery system.

## Scenarios Overview

| ID | Scenario | Target VM | Provocation Method | Expected Detection |
|---|---|---|---|---|
| 01 | **Nginx Syntax Error** | Proxy (10.0.27.228) | Corrupt `nginx.conf` | 502 Bad Gateway / SSH `nginx -t` |
| 02 | **SQL Injection (Security)** | Web (10.0.27.223) | Malicious Form Payload | Application Log Pattern Match |
| 03 | **DB Connectivity (Firewall)** | DB (10.0.27.239) | Block Port 5432 via iptables | Web App connection errors |
| 04 | **Resource Exhaustion (Disk)** | Any VM | Fill disk with `dd` | OS Error: No space left |
| 05 | **Certificate Expiry (Mock)** | Proxy (10.0.27.228) | Update dummy expiry file | Log check on expiry date |

---

## Directory Structure
Each subfolder contains:
- `README.md`: Instructions for the demo.
- `provoke.sh`: Script to break the service.
- `restore.sh`: Script to fix it manually.
- `prompt_update.txt`: Suggested updates for Odin's system prompt.
