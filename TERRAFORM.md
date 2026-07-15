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

