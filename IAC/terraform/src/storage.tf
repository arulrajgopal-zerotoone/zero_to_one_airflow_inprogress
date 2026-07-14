# Storage Account backing the "DAG files + logs" Blob store in the architecture diagram
resource "azurerm_storage_account" "airflow" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "dags" {
  name                  = var.dags_container_name
  storage_account_id    = azurerm_storage_account.airflow.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = var.logs_container_name
  storage_account_id    = azurerm_storage_account.airflow.id
  container_access_type = "private"
}

# Lets the VM's managed identity read/write DAGs and logs via the Blob data plane
resource "azurerm_role_assignment" "vm_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.airflow.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.airflow.identity[0].principal_id
}
