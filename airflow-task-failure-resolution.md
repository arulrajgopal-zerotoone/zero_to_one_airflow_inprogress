# Airflow 3 — Task Fails Instantly with No Log File (Resolution)

**Date:** 2026-07-15
**Environment:** Airflow 3.x on Docker Compose (Azure VM `vm-airflow-dev`), LocalExecutor
**DAG:** `test_job` (simple BashOperator tasks)

---

## Symptom

- Triggering the DAG caused tasks to go straight from `queued` → `failed`.
- The log directory structure was created, but **no `attempt=1.log` file** appeared:
  ```
  /opt/airflow/logs/dag_id=test_job/run_id=.../task_id=print_start_time/attempt=1.log  ← missing
  ```
- Scheduler logged:
  ```
  Executor LocalExecutor(parallelism=32) reported that the task instance
  <TaskInstance: test_job.print_start_time ... [queued]> finished with state failed,
  but the task instance's state attribute is queued.
  ```

## Diagnosis Steps

1. **`airflow tasks test test_job print_start_time 2021-01-01`** (inside the scheduler container)
   → Task ran **successfully**. This ruled out DAG parsing errors, DB connectivity, and the task itself.
   → Note: `tasks test` used `http://in-process.invalid.` for the Execution API — real runs don't get this in-process shortcut.

2. **Log directory permission check**
   ```bash
   docker exec -it airflow-scheduler-1 bash -c 'touch "/opt/airflow/logs/dag_id=test_job/writetest" && echo WRITE_OK'
   ```
   → `WRITE_OK` — permissions were fine (owner `airflow`, group-writable). Ruled out the classic root-owned logs mount issue.

3. **Raw scheduler logs during a fresh failing run**
   ```bash
   docker logs --since=5m airflow-scheduler-1 2>&1 | tail -100
   ```
   → Revealed the actual traceback.

## Root Cause

The task supervisor process crashed **at startup**, before it could open its log file:

```
File ".../airflow/sdk/execution_time/supervisor.py", line 811, in _on_child_started
    ti_context = self.client.task_instances.start(ti.id, self.pid, start_date)
...
httpx.ConnectError: [Errno 111] Connection refused
```

In **Airflow 3**, every task process must communicate with the **Execution API server** over HTTP
(`PATCH /execution/task-instances/{id}/run`, etc.).

The config `core.execution_api_server_url` was left at its default
(`http://localhost:8080/execution/`). Inside the **scheduler container**, nothing listens on
`localhost:8080` — the API server runs in a **separate container** (`airflow-webserver-1`).
Result: every real task run died instantly with `Connection refused`, producing the
queued → failed pattern with no task log ever written.

`airflow tasks test` worked because it bypasses this with an in-process API client.

## Fix

Point the scheduler (task runners) at the API server **service name** in `docker-compose.yaml`:

```yaml
environment:
  AIRFLOW__CORE__EXECUTION_API_SERVER_URL: http://airflow-webserver:8080/execution/
```

- `airflow-webserver` must match the compose **service** name (check `docker compose ps`),
  not the container name `airflow-webserver-1`.
- The service must be running `airflow api-server` (serves both UI and `/execution/` API).
- Containers must share a docker network (default compose networking is sufficient).

Apply and verify:

```bash
cd <compose directory>
docker compose down && docker compose up -d

# Verify the API is reachable from the scheduler container
docker exec -it airflow-scheduler-1 python -c \
  "import urllib.request; print(urllib.request.urlopen('http://airflow-webserver:8080/execution/').status)"
# (a 401/404 is fine — it proves the port answers; 'Connection refused' means wrong host/service)

# Re-trigger
docker exec -it airflow-scheduler-1 airflow dags trigger test_job
```

After the fix, tasks execute normally and `attempt=1.log` files are written.

## Additional Notes

- A secondary error appeared during the failures:
  `DAG 'test_job' not found in serialized_dag table` — a side effect of the churn;
  it clears once the dag-processor reserializes the DAG.
- Reminder from earlier in the investigation: `BASE_DIR` in the DAG resolves relative to the
  DAG file's location on the **executing** container, so `/opt/airflow/tasks/test.py` must
  exist (be mounted) wherever tasks run — relevant for task `say_hello` (`t2`).

## Key Takeaway

In Airflow 3 multi-container deployments, **`AIRFLOW__CORE__EXECUTION_API_SERVER_URL` must
point at the api-server container by service name**. The default `localhost:8080` only works
when the api-server runs in the same container as the task processes. The telltale signature
of this misconfiguration: tasks fail from `queued` with no task log, while `airflow tasks test`
succeeds.
