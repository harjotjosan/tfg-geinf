# Incident Detection & Replication Guide

This document outlines the various incidents that the Vector logging system is configured to detect and how to intentionally trigger them for demonstration or testing purposes.

## General Information
- The detection system uses `Vector` to tail the central application log (`/var/log/remote/10.0.27.223/docker-carparts-web.log`).
- Incidents are filtered using regular expressions (regex).
- The system includes a **60-second cooldown** per incident pattern, meaning duplicate events of the same pattern within a 1-minute window are throttled to prevent spam. 

---

## 1. Test Event (`test_event`)
This incident is triggered when specific test phrases are logged. It's intended purely to verify that the monitoring pipeline is working.
- **Severity:** `info`
- **Matched Regex:** `TEST_DOCKER_(CARPARTS|EXPORT)_TFG` or `TEST_log_detector`
- **How to Replicate:**
  Append a manual test line directly into the log file:
  ```bash
  echo "$(date --utc +%Y-%m-%dT%H:%M:%SZ) web1 docker-carparts-web: [INFO] TEST_log_detector" >> /var/log/remote/10.0.27.223/docker-carparts-web.log
  ```

---

## 2. Gunicorn Worker Crash/Exit (`worker_exit`)
This detects when a worker process terminates gracefully or otherwise cleanly exits.
- **Severity:** `critical`
- **Matched Regex:** `Worker exiting`
- **How to Replicate:**
  Identify a running worker process and kill it, forcing Gunicorn to spawn a new one. The termination will log an exit message.
  1. Find a worker PID using `ps aux | grep gunicorn` on the application server.
  2. Kill the worker: `kill -TERM <PID>`
  3. *Alternatively*, simulate it by appending:
     ```bash
     echo "$(date --utc +%Y-%m-%dT%H:%M:%SZ) web1 docker-carparts-web: [INFO] Worker exiting (pid: 999)" >> /var/log/remote/10.0.27.223/docker-carparts-web.log
     ```

---

## 3. Database Connection Failure (`database_failure`)
This detects when the web application fails to communicate with its backend database.
- **Severity:** `critical`
- **Matched Regex:** `Connection refused` or `OperationalError` (case-insensitive)
- **How to Replicate:**
  1. SSH into the server hosting your application.
  2. Stop the database container temporarily:
     ```bash
     docker stop <name_of_database_container>
     ```
  3. Generate traffic by attempting to load the web application in your browser. The application will error out because the database is unreachable, generating connection errors.
  4. Bring the database back up: `docker start <name_of_database_container>`

---

## 4. Gunicorn Worker Timeout (`worker_timeout`)
This event triggers when a request hangs for too long (such as an infinite loop or deadlock), forcing the Gunicorn master process to kill the stuck worker.
- **Severity:** `high`
- **Matched Regex:** `worker timeout` (case-insensitive)
- **How to Replicate:**
  Suspend a worker process manually so it becomes unresponsive.
  1. Find a running worker PID using `ps aux | grep gunicorn` on the server.
  2. Suspend the worker:
     ```bash
     kill -STOP <PID>
     ```
  3. Wait approximately 30 seconds (Gunicorn's default timeout). The master process will realize it's frozen and print `[ERROR] Gunicorn worker timeout, dropping connection`.
  4. (Optional) Resume the worker if needed: `kill -CONT <PID>`

---

## 5. Out Of Memory / Kernel Kill (`oom_crash`)
This catches incidents where the Linux kernel's Out-Of-Memory (OOM) killer sacrifices the application process to save system stability. 
- **Severity:** `critical`
- **Matched Regex:** `Out of memory` or `Killed process` (case-insensitive)
- **How to Replicate:**
  Since forcing a real OOM kill requires creating a memory-leak script, the safest way to demonstrate this is by simulating the kernel log message directly into your log file:
  ```bash
  echo "$(date --utc +%Y-%m-%dT%H:%M:%SZ) web1 kernel: Out of memory: Killed process 1234 (gunicorn)" >> /var/log/remote/10.0.27.223/docker-carparts-web.log
  ```

---

## 6. General Exception / Code Error (`gunicorn_error`)
A generic catch-all for Python traceback exceptions and standard application errors.
- **Severity:** `critical`
- **Matched Regex:** `[ERROR]`, `Traceback`, or `Exception`
- **How to Replicate:**
  Trigger a 500 Internal Server Error in your web application (if you have an endpoint designed to fail), or simulate it by injecting an error stack trace:
  ```bash
  echo "$(date --utc +%Y-%m-%dT%H:%M:%SZ) web1 docker-carparts-web: [ERROR] Exception: Failed to process request" >> /var/log/remote/10.0.27.223/docker-carparts-web.log
  ```
