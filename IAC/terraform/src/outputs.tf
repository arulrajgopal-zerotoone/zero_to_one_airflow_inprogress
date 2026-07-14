output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.airflow.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "postgres_server_fqdn" {
  value = azurerm_postgresql_flexible_server.airflow.fqdn
}

output "postgres_database_name" {
  value = azurerm_postgresql_flexible_server_database.metadata.name
}

output "storage_account_name" {
  value = azurerm_storage_account.airflow.name
}

output "dags_container_name" {
  value = azurerm_storage_container.dags.name
}

output "logs_container_name" {
  value = azurerm_storage_container.logs.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
