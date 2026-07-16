# Deployment

# Deploy to Azure (Terraform)

Infra lives in [IAC/terraform/](IAC/terraform/): a resource group, VNet/NSG,
an Airflow VM (Docker Compose, LocalExecutor), an Azure Postgres Flexible
Server (metadata DB), a Storage Account (`dags`/`logs` blob containers) and a
Key Vault holding the generated connection strings.

## Prerequisites

- An Azure subscription
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in (`az login`)
- Your current public IP (`curl -s ifconfig.me`) — the NSG only allows SSH/8080 from this IP

## 1. Create a service principal for Terraform

The `azurerm` provider ([main.tf](IAC/terraform/src/main.tf)) authenticates
with a service principal, not your interactive `az login` session:

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az ad sp create-for-rbac --name sp-airflow-tf --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID
# note the appId (client_id), password (client_secret) and tenant from the output
```

## 2. Export the sensitive variables

These are intentionally **not** in `dev.tfvars` so secrets never land in
source control — pass them as environment variables:

```bash
export TF_VAR_tenant_id="<tenant>"
export TF_VAR_subscription_id="$SUBSCRIPTION_ID"
export TF_VAR_client_id="<appId>"
export TF_VAR_client_secret="<password>"
export TF_VAR_vm_admin_username="<pick-a-vm-admin-username>"
export TF_VAR_vm_admin_password="<pick-a-strong-password>"
export TF_VAR_postgres_admin_username="<pick-a-postgres-admin-username>"
export TF_VAR_postgres_admin_password="<pick-a-strong-password>"
export TF_VAR_postgres_server_name="<globally-unique-psql-server-name>"
export TF_VAR_postgres_database_name="<airflow-metadata-db-name>"
export TF_VAR_postgres_data_database_name="<data-db-name>"
```

## 3. Review `dev.tfvars`

Open [IAC/terraform/config/dev.tfvars](IAC/terraform/config/dev.tfvars) and:

- Set `allowed_source_ip` to `"<your-ip>"`
- Check `storage_account_name` / `key_vault_name` are still globally unique
  (rename if `terraform apply` reports a name collision)

## 4. Init, plan, apply

```bash
cd IAC/terraform/src
terraform init
terraform plan  -var-file="../config/dev.tfvars"
terraform apply -var-file="../config/dev.tfvars"
```
Capture the output from `terraform apply` — it is used in the steps below.

On first boot, the VM's `custom_data`
([scripts/install_docker.sh](IAC/terraform/install_docker.sh))
installs Docker, pulls the Postgres connection string from Key Vault, and
starts the webserver/scheduler stack
([docker-compose.yml](docker-compose.yml)).
This takes a few minutes after `apply` finishes.

---

# Deployment Steps

Steps to deploy and run the DAGs.

These steps will happen after terraform apply.

## 1. Set up GitHub secrets

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

## 2. Verify the VM setup (via PuTTY)

Use the `vm_public_ip` output from Terraform, and the username/password from:

- `TF_VAR_vm_admin_username`
- `TF_VAR_vm_admin_password`

## 3. Verify the Postgres server setup (via pgAdmin)

- **Server name:** `TF_VAR_postgres_server_name` + `.postgres.database.azure.com` suffix (or the `postgres_server_fqdn` output from Terraform)
- **Database name:** `TF_VAR_postgres_database_name` & `TF_VAR_postgres_data_database_name`
- **Username / password:** `TF_VAR_postgres_admin_username` & `TF_VAR_postgres_admin_password`

## 4. Manually trigger the deploy workflows (first time)

On the first deploy, nothing has been pushed to `main` yet, so trigger both workflows manually once via Actions → *workflow name* → Run workflow (`workflow_dispatch`), optionally overriding the `resource_group`/`vm_name` inputs — no local `az login` session needed:

- **[Deploy Compose Stack](.github/workflows/deploy-compose.yml)** — updates the running stack on the VM to match `docker-compose.yml`.
- **[Deploy DAGs](.github/workflows/deploy-dags.yml)** — publishes `src/dags/`/`src/tasks/` to the `dags` blob container and syncs them onto the VM.

Note the VM has no periodic sync timer or persistent sync script of its own ([install_docker.sh](IAC/terraform/install_docker.sh) only sets the stack up on first boot); each workflow pushes state to the VM itself on every run.

After this first manual run, subsequent syncs are taken care of by pushing to `main`: **Deploy Compose Stack** re-runs on any push touching `docker-compose.yml`, and **Deploy DAGs** re-runs on any push touching `src/dags/**` or `src/tasks/**`. If storage and the VM ever drift outside of a push to `main` (e.g. after a VM restart), re-run either workflow manually the same way.

## 5. Check DAG sync and Airflow processes are up

**DAGs and tasks path on the VM** — navigate here and run `ll` to confirm the DAGs and tasks were copied over:

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
airflow-dag-processor-1   Up 3 hours
airflow-webserver-1       Up 3 hours
airflow-scheduler-1       Up 3 hours
```


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

