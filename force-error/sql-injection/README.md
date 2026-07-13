# Loki 4: SQL Injection Scenario

This scenario demonstrates the detection and mitigation of an SQL Injection vulnerability on the Web application tier of the GEMRAT infrastructure.

## Scenario Overview

The scenario consists of two parts:

1. **Vulnerability Toggle**: When the environment variable `SQL_INJECTION_VULNERABLE` is set to `"true"` on the web tier, the application searches for car parts using string interpolation (direct f-string formatting), making it vulnerable to SQL injection. When the variable is `"false"` or absent, the application runs secure parameterized queries.
2. **Log Detection**: Regardless of whether the vulnerability is active, a simple pattern detector in the application checks search queries for common SQL Injection signatures (`union`, `select`, `--`). If found, it prints `[SECURITY] SQL Injection attempt detected` to the standard output.
3. **Log Centralization & Routing**: `rsyslog` forwards the web application logs to the Control VM, where Vector parses them. If Vector detects the SQL Injection log pattern, it routes the incident to a dedicated security webhook (`n8n_security_webhook`) and logs it to a local security audit file (`/var/lib/vector/security_audit.log`).

## Files in this Scenario

- `provoke.sh`: Activates the vulnerability by setting `SQL_INJECTION_VULNERABLE=true` in the docker-compose file of the web tier, restarts the web container, and triggers a mock SQL Injection payload via curl.
- `restore.sh`: Disables the vulnerability by setting `SQL_INJECTION_VULNERABLE=false` in the docker-compose file and restarts the web container.
- `odin_v2_system_prompt.txt`: Guidance for the Odin agent on how to diagnose, verify, and resolve this security incident.

## How to Test

1. Execute `provoke.sh` on the Web VM (10.0.27.223) to enable the SQL injection vulnerability.
2. Verify the vulnerability by querying the application with an SQL Injection payload.
3. Observe `[SECURITY] SQL Injection attempt detected` in Gunicorn/Flask container logs.
4. Execute `restore.sh` to remediate the vulnerability and verify that parameterized queries are once again used.

### Manual testing

#### 1. Visual UNION Injection

This payload injects a fake car part into the website's results table to visibly demonstrate successful exploitation:

sql

`test') UNION SELECT 'INJ-999', '⚠️ MALICIOUS INJECTED PART ⚠️', 'Security Test', 'HackCorp', 999, 13.37, 'Universal' --`

- **What happens:**
  - **In the UI:** A new row displaying `⚠️ MALICIOUS INJECTED PART ⚠️` with price `13.37 €` will appear in the search results table!
  - **In the Logs:** Flask detects `union`, `select`, and `--`, outputting `[SECURITY] SQL Injection attempt detected`.
  - **In Vector:** Vector matches `union select` and `SQL Injection`, generating a critical `sql_injection` incident for Heimdall/Odin.

---

#### 2. Standard UNION Payload

A standard payload matching schema column counts:

sql

`' UNION SELECT '1', 'SQL Injection Test', 'Test', 'Attacker', 10, 20.0, 'All' --`

---

#### 3. Database Error Generator (Error-Based)

If you want to test database exception handling and error logging:

sql

`') UNION SELECT '1', '2' --`

- **What happens:** PostgreSQL throws a column mismatch error (`UNION types cannot be matched` or column count mismatch), causing Flask to log a database exception while still firing the security warning.
