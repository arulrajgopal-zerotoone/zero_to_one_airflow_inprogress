# zero_to_one_airflow

Airflow-based ETL demo: DAGs load an orders/customers/products schema into
Postgres via a couple of stored procedures. See [Architecture.md](Architecture.md)
for the business and technical architecture.

For deploying the infrastructure and DAGs to Azure, see [TERRAFORM.md](TERRAFORM.md).

# Deploy DAGs & the Compose Stack

Once `terraform apply` has finished and the VM has booted, two workflows keep
the running VM in sync with this repo — no local `az login` session needed:

- **[Deploy DAGs](.github/workflows/deploy-dags.yml)** runs automatically on
  every push to `main` touching `src/dags/**` or `src/tasks/**`, or manually
  via Actions → Deploy DAGs → Run workflow. It uploads `src/dags/` and
  `src/tasks/` into the `dags` blob container; the VM's
  `airflow-blob-sync.timer` (installed by
  [install_docker.sh](IAC/terraform/install_docker.sh)) pulls them down within
  ~3 minutes.
- **[Deploy Compose Stack](.github/workflows/deploy-compose.yml)** runs
  automatically on every push to `main` touching
  `docker-compose.yml`, or manually via Actions → Deploy Compose
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

Also add repo secrets `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER` and
`POSTGRES_PASSWORD` — credentials for the "data" database that
`src/create_insert/*.py` and `src/tasks/load_*.py` connect to (read via
`os.environ`, no longer hardcoded). **Deploy Compose Stack** upserts these
into `/opt/airflow/.env` on the VM on every run, and `docker-compose.yml`
passes them into the scheduler container's environment, where the
`BashOperator`-spawned task scripts inherit them.

Provisioning/teardown (`terraform apply`/`destroy`) is **not** wired into CI
since state is local ([versions.tf](IAC/terraform/src/versions.tf) has no
remote backend configured) — keep running those from your machine per the
Terraform section above. Starting/stopping the VM or reading the webserver
admin password also isn't wired into CI currently — do those over SSH or
`az vm start`/`az vm deallocate` directly.

