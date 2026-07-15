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

# Deploy DAGs & the Compose Stack

Once `terraform apply` has finished and the VM has booted, two workflows keep
the running VM in sync with this repo — no local `az login` session needed:

- **[Deploy DAGs](.github/workflows/deploy-dags.yml)** runs automatically on
  every push to `main` touching `src/dags/**` or `src/tasks/**`, or manually
  via Actions → Deploy DAGs → Run workflow. It uploads `src/dags/` and
  `src/tasks/` into the `dags` blob container; the VM's
  `airflow-blob-sync.timer` (installed by
  [install_docker.sh](src/scripts/install_docker.sh)) pulls them down within
  ~3 minutes.
- **[Deploy Compose Stack](.github/workflows/deploy-compose.yml)** runs
  automatically on every push to `main` touching
  `src/scripts/docker-compose.yml`, or manually via Actions → Deploy Compose
  Stack → Run workflow (optionally overriding the `resource_group`/`vm_name`
  inputs). It pushes the compose file to the VM and runs
  `docker compose up -d` via `az vm run-command invoke`, so a change to the
  stack definition doesn't require SSH-ing in and editing
  `/opt/airflow/docker-compose.yml` by hand.

`az vm run-command invoke` goes through the Azure control plane rather than
SSH, so **Deploy Compose Stack** works even though the NSG
([network.tf](IAC/terraform/src/network.tf)) only allows SSH/8080 from the
developer's own IP.

One-time setup — add a repo secret `AZURE_CREDENTIALS`, the JSON output of an
`az ad sp create-for-rbac --sdk-auth`-style credential
(`{"clientId", "clientSecret", "subscriptionId", "tenantId"}`), for a service
principal with:

- Key Vault "Get/List" on secrets (same access the Terraform deployer in
  [keyvault.tf](IAC/terraform/src/keyvault.tf) has) — used by **Deploy DAGs**
  to read the storage connection string.
- Contributor on the VM — used by **Deploy Compose Stack** to run
  `az vm run-command invoke`.

Optionally add a repo variable `KEY_VAULT_NAME` if it differs from the
`kaninipro-kv-airflow-dev` default in [dev.tfvars](IAC/terraform/config/dev.tfvars).

Provisioning/teardown (`terraform apply`/`destroy`) is **not** wired into CI
since state is local ([versions.tf](IAC/terraform/src/versions.tf) has no
remote backend configured) — keep running those from your machine per the
Terraform section above. Starting/stopping the VM or reading the webserver
admin password also isn't wired into CI currently — do those over SSH or
`az vm start`/`az vm deallocate` directly.

