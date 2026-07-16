# Deployment Steps

Steps to deploy and run the DAGs.

## 1. Prepare infrastructure

Go through [TERRAFORM.md](TERRAFORM.md) and provision all Azure infra.

All the needed infra is kept under [IAC/terraform/](IAC/terraform/).

Capture the output from `terraform apply` — it is used in the steps below.

## 2. Set up GitHub secrets

`AZURE_CREDENTIALS` (JSON, same format as `az ad sp create-for-rbac --sdk-auth`):

```json
{
    "clientId": "xxxx",
    "clientSecret": "xxxx",
    "subscriptionId": "xxxx",
    "tenantId": "xxxx"
}
```

Plus the data-DB credentials:

- `POSTGRES_HOST`
- `POSTGRES_DATA_DB`
- `POSTGRES_AIRFLOW_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`

> **Note:** these Postgres secrets must match what was provided locally during the Terraform deployment. Reference:
>
> | GitHub secret        | Terraform variable                     |
> |----------------------|----------------------------------------|
> | `POSTGRES_HOST`      | `TF_VAR_postgres_server_name`          |
> | `POSTGRES_DATA_DB`   | `TF_VAR_postgres_data_database_name`   |
> | `POSTGRES_AIRFLOW_DB`| `TF_VAR_postgres_database_name`        |
> | `POSTGRES_USER`      | `TF_VAR_postgres_admin_username`       |
> | `POSTGRES_PASSWORD`  | `TF_VAR_postgres_admin_password`       |

## 3. Verify the VM setup (via PuTTY)

Use the `vm_public_ip` output from Terraform, and the username/password from:

- `TF_VAR_vm_admin_username`
- `TF_VAR_vm_admin_password`

## 4. Verify the Postgres server setup (via pgAdmin)

- **Server name:** `TF_VAR_postgres_server_name` + `.postgres.database.azure.com` suffix (or the `postgres_server_fqdn` output from Terraform)
- **Database name:** `TF_VAR_postgres_database_name` & `TF_VAR_postgres_data_database_name`
- **Username / password:** `TF_VAR_postgres_admin_username` & `TF_VAR_postgres_admin_password`

## 5. Push to `main`

Pushing to the `main` branch triggers the GitHub workflows that:

- Deploy the Airflow Docker Compose stack ([deploy-compose.yml](.github/workflows/deploy-compose.yml))
- Promote the DAGs and tasks to the storage account ([deploy-dags.yml](.github/workflows/deploy-dags.yml))

Once the DAGs/tasks land in storage, they get synced onto the VM by the sync logic in [install_docker.sh](IAC/terraform/install_docker.sh).

## 6. Log in to Airflow and test it

- **Airflow host:** `http://<vm_public_ip>:8080/` (`vm_public_ip` from the Terraform output)
- **Username:** `admin`
- **Password:** extracted by running this on the VM:

  ```bash
  cat /opt/airflow/simple_auth_manager_passwords.json.generated
  ```

Once logged in, wait a few minutes, then run the `test_job` DAG to validate the deployment.

## 7. Run the actual jobs

Run the `ddl_setup` DAG first, then the `data_proc` DAG (actual data processing).

## 8. Additional info

**DAGs and tasks path on the VM:**

```bash
cd /opt/airflow/dags
cd /opt/airflow/tasks
```

**Check dag-processor, webserver and scheduler status on the VM:**

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Sample output:

```
NAMES                     STATUS
airflow-dag-processor-1   Up About an hour
airflow-webserver-1       Up 3 hours
airflow-scheduler-1       Up 3 hours
```
