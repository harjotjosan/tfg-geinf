# Scenario 03: DB Connectivity (Firewall)

## Description
This test simulates a network connectivity issue or a misconfigured firewall where traffic to the PostgreSQL port (5432) is blocked on the DB VM. This results in the Flask Web Application failing to connect to the database, causing search/filter requests to fail and the `/health` endpoint to return a 503 status code.

## Target
- **VM:** DB VM (10.0.27.239)
- **Service:** PostgreSQL (port 5432)
- **System Tool:** `iptables`

## Instructions
1. Copy `provoke.sh` to the DB VM or run the commands via SSH.
2. Observe n8n detection (should detect a failure in the Web App health check, showing connection timeouts to the DB).
3. The LLM (Odin) should:
   - SSH into the DB VM (or check the Web VM first, then connect to the DB VM).
   - Test connectivity (e.g., using `nc`, `telnet`, `ping`, or check local firewall rules with `iptables -L`).
   - Identify that port 5432 is blocked by iptables rules.
   - Propose a fix (removing the block rules).

## Files
- `provoke.sh`: Blocks incoming traffic to port 5432 via iptables.
- `restore.sh`: Cleans up the iptables rules to restore DB connectivity.
- `odin_v2_system_prompt.txt`: System prompt for Odin with database and firewall troubleshooting guidelines.
