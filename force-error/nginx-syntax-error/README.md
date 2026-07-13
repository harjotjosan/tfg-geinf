# Scenario 01: Nginx Syntax Error

## Description
This test simulates a human error where an administrator modifies the Nginx configuration on the Proxy VM and introduces a syntax error (e.g., a missing semicolon or an invalid directive). This usually results in Nginx failing to reload or returning errors if the master process was stopped.

## Target
- **VM:** Proxy VM (10.0.27.228)
- **Service:** Nginx
- **File:** `/etc/nginx/nginx.conf`

## Instructions
1. Copy `provoke.sh` to the Proxy VM or run the commands via SSH.
2. Observe n8n detection (should detect a failure in the website health check).
3. The LLM (Odin) should:
   - SSH into the Proxy VM.
   - Run `nginx -t` to diagnose.
   - Identify the syntax error.
   - Propose a fix (restoring the backup or fixing the line).

## Files
- `provoke.sh`: Breaks the Nginx config.
- `restore.sh`: Restores the Nginx config from a backup.
- `odin_v2_system_prompt.txt`: Updated prompt for multi-tier awareness.
