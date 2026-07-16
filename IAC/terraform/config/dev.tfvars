# variables
#
# Sensitive/environment-specific values (vm_admin_username, vm_admin_password,
# postgres_admin_username, postgres_admin_password, tenant_id, subscription_id,
# client_id, client_secret) are intentionally NOT set here — pass them via
# TF_VAR_<name> environment variables or -var on the CLI/CI so secrets never
# land in source control.

resource_group_name = "rg-airflow-dev"

# Set this to the developer's own IP before applying, e.g. "203.0.113.10"
# allowed_source_ip = "REPLACE_WITH_YOUR_IP"
allowed_source_ip = "27.5.83.181"

vm_name = "vm-airflow-dev"

postgres_server_name    = "kaninipro-psql-airflow-dev"
postgres_database_name  = "airflow_metadata"

# Must be globally unique, lowercase alphanumeric, 3-24 chars
storage_account_name = "kaniniprostairflowdev"

key_vault_name = "kaninipro-kv-airflow-dev"
