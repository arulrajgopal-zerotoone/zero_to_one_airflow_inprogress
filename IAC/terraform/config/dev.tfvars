# variables
#
# Sensitive values (postgres_admin_password, vm_admin_password, tenant_id,
# subscription_id, client_id, client_secret) are intentionally NOT set here —
# pass them via TF_VAR_<name> environment variables or -var on the CLI/CI so
# secrets never land in source control.

resource_group_name = "rg-airflow-dev"

# Set this to the developer's own IP before applying, e.g. "203.0.113.10/32"
allowed_source_ip_cidr = "REPLACE_WITH_YOUR_IP/32"

vm_name = "vm-airflow-dev"

postgres_server_name    = "psql-airflow-dev"
postgres_database_name  = "airflow_metadata"

# Must be globally unique, lowercase alphanumeric, 3-24 chars
storage_account_name = "stairflowdev"

key_vault_name = "kv-airflow-dev"
