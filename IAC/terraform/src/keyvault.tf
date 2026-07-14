resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tenant_id = var.tenant_id
  sku_name  = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
}

# Lets the identity applying this Terraform config manage secrets
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

# Lets the Airflow VM's managed identity read the DB/storage secrets at runtime
resource "azurerm_key_vault_access_policy" "airflow_vm" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_linux_virtual_machine.airflow.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_secret" "postgres_connection_string" {
  name         = "airflow-postgres-connection-string"
  key_vault_id = azurerm_key_vault.kv.id
  value        = "postgresql+psycopg2://${var.postgres_admin_username}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.airflow.fqdn}:5432/${var.postgres_database_name}?sslmode=require"

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "airflow-storage-connection-string"
  key_vault_id = azurerm_key_vault.kv.id
  value        = azurerm_storage_account.airflow.primary_connection_string

  depends_on = [azurerm_key_vault_access_policy.deployer]
}
