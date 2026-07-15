# zero_to_one_airflow

Airflow-based ETL demo: DAGs load an orders/customers/products schema into
Postgres via a couple of stored procedures. See [Architecture.md](Architecture.md)
for the business and technical architecture.

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
export TF_VAR_vm_admin_password="<pick-a-strong-password>"
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
terraform plan  -var-file="../config/dev.tfvars"
terraform apply -var-file="../config/dev.tfvars"
```

Note the outputs (`vm_public_ip`, `storage_account_name`, `key_vault_name`,
`postgres_server_fqdn`) — you'll need them below.

On first boot, the VM's `custom_data`
([scripts/install_docker.sh](src/scripts/install_docker.sh))
installs Docker, pulls the Postgres connection string from Key Vault, and
starts the webserver/scheduler stack
([scripts/docker-compose.yml](src/scripts/docker-compose.yml)).
This takes a few minutes after `apply` finishes.

---

# Deploy DAGs & Operate the VM

Once `terraform apply` has finished and the VM has booted,
[.github/workflows/deploy-dags.yml](.github/workflows/deploy-dags.yml) and
[.github/workflows/operate-vm.yml](.github/workflows/operate-vm.yml) push DAG
code and operate the VM — no local `az login` session needed. One-time setup:

- Add a repo secret `AZURE_CREDENTIALS` — the JSON output of an
  `az ad sp create-for-rbac --sdk-auth`-style credential
  (`{"clientId", "clientSecret", "subscriptionId", "tenantId"}`) for a
  service principal that already has Key Vault "Get/List" on secrets
  (same access the Terraform deployer in [keyvault.tf](IAC/terraform/src/keyvault.tf)
  has) and Contributor on the VM.
- Optionally add a repo variable `KEY_VAULT_NAME` if it differs from the
  `kaninipro-kv-airflow-dev` default in [dev.tfvars](IAC/terraform/config/dev.tfvars).

**Deploy DAGs** runs automatically on every push to `main` touching
`src/dags/**` or `src/tasks/**`, or manually via
Actions → Deploy DAGs → Run workflow.

**Operate VM** is manual-only (Actions → Operate VM → Run workflow) and takes
an `action` input:

| action           | what it does                                                        |
|------------------|----------------------------------------------------------------------|
| `status`         | prints VM power state + `docker compose ps` output                  |
| `start`          | `az vm start`                                                       |
| `stop`           | `az vm deallocate` (stops billing for compute; disks are preserved) |
| `restart-stack`  | `docker compose down && up -d` on the VM                            |
| `sync-now`       | forces `airflow-blob-sync.service` instead of waiting ~3 minutes     |
| `login-info`     | prints the webserver UI URL (`http://<vm-ip>:8080`) and the auto-generated `admin` password |

These use `az vm run-command invoke` / `az vm start`/`deallocate`, which go
through the Azure control plane rather than SSH — they work even though the
NSG ([network.tf](IAC/terraform/src/network.tf)) only allows SSH/8080 from the
developer's own IP. Provisioning/teardown (`terraform apply`/`destroy`) is
**not** wired into CI since state is local ([versions.tf](IAC/terraform/src/versions.tf)
has no remote backend configured) — keep running those from your machine per
the Terraform section above.

