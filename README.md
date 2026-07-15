# zero_to_one_airflow

Airflow-based ETL demo: DAGs load an orders/customers/products schema into
Postgres via a couple of stored procedures. See [Architecture.md](Architecture.md)
for the target Azure architecture.

# ER diagram for the workflow

![image](https://github.com/user-attachments/assets/7e3feb42-b7d3-4dce-899b-c56eec999387)

# data pipeline flow

![image](https://github.com/user-attachments/assets/17c776d1-8d13-47c0-b502-e61b412070a8)

---

# Deploy to Azure (Terraform)

Infra lives in [IAC/terraform/](IAC/terraform/): a resource group, VNet/NSG,
an Airflow VM (Docker Compose, LocalExecutor), an Azure Postgres Flexible
Server (metadata DB), a Storage Account (`dags`/`logs` blob containers) and a
Key Vault holding the generated connection strings.

## Prerequisites

- An Azure subscription
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in (`az login`)
- An SSH key pair for VM access (`ssh-keygen -t ed25519 -f ~/.ssh/airflow_vm` if you don't have one)
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
export TF_VAR_postgres_admin_password="<pick-a-strong-password>"
export TF_VAR_vm_ssh_public_key="$(cat ~/.ssh/airflow_vm.pub)"
```

## 3. Review `dev.tfvars`

Open [IAC/terraform/config/dev.tfvars](IAC/terraform/config/dev.tfvars) and:

- Set `allowed_source_ip_cidr` to `"<your-ip>/32"`
- Check `storage_account_name` / `key_vault_name` are still globally unique
  (rename if `terraform apply` reports a name collision)

## 4. Init, plan, apply

```bash
cd IAC/terraform/src
terraform init
terraform plan  -var-file=../config/dev.tfvars
terraform apply -var-file=../config/dev.tfvars
```

Note the outputs (`vm_public_ip`, `storage_account_name`, `key_vault_name`,
`postgres_server_fqdn`) — you'll need them below.

On first boot, the VM's `custom_data`
([scripts/install_docker.sh](src/scripts/install_docker.sh))
installs Docker, pulls the Postgres connection string from Key Vault, and
starts the webserver/scheduler stack
([scripts/docker-compose.yml](src/scripts/docker-compose.yml)).
This takes a few minutes after `apply` finishes.

## 5. Upload the DAGs and tasks to Blob Storage

The VM syncs DAGs *from* Blob every 3 minutes (it doesn't read this git repo
directly). Push this repo's `src/dags/` and `src/tasks/` folders into the
`dags` container using the connection string Terraform generated:

```bash
KEY_VAULT_NAME=<key_vault_name output>
CONN=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" \
  --name airflow-storage-connection-string --query value -o tsv)

az storage blob upload-batch --connection-string "$CONN" \
  -d dags -s src/dags --destination-path dags

az storage blob upload-batch --connection-string "$CONN" \
  -d dags -s src/tasks --destination-path tasks
```

Re-run these two commands whenever DAG/task code changes; the VM's
`airflow-blob-sync.timer` picks them up within ~3 minutes.

## 6. Log in to the webserver UI

```bash
VM_IP=<vm_public_ip output>
ssh azureuser@$VM_IP -i ~/.ssh/airflow_vm   # matches vm_admin_username in variables.tf

sudo docker compose -f /opt/airflow/docker-compose.yml ps
cat /opt/airflow/simple_auth_manager_passwords.json.generated   # admin password
```

Open `http://<vm_public_ip>:8080` and log in as `admin` with that password
(same convention as the local venv setup below).

## 7. Tear down

```bash
terraform destroy -var-file=../config/dev.tfvars
```

---

# Local / manual setup (no Azure)

For running everything on a single machine without the Terraform stack, see
[old_README.md](old_README.md) — installs Postgres + a Python venv + Airflow
directly via `setup.sh` / `deploy_dags.sh`.
