# Azure Database for PostgreSQL Flexible Server — Airflow metadata DB
resource "azurerm_postgresql_flexible_server" "airflow" {
  name                = var.postgres_server_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  version    = var.postgres_version
  sku_name   = var.postgres_sku_name
  storage_mb = var.postgres_storage_mb

  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password

  # Public access, locked down to the Airflow VM's IP via the firewall rule below.
  # Hardening TODO: move to VNet-delegated private access once a delegated
  # subnet + private DNS zone are provisioned.
  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "metadata" {
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.airflow.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "data" {
  name      = var.postgres_data_database_name
  server_id = azurerm_postgresql_flexible_server.airflow.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Only the Airflow VM's public IP may reach the metadata DB
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_vm" {
  name             = "AllowAirflowVM"
  server_id        = azurerm_postgresql_flexible_server.airflow.id
  start_ip_address = azurerm_public_ip.vm.ip_address
  end_ip_address   = azurerm_public_ip.vm.ip_address
}

# Also let the developer's own IP (allowed_source_ip) reach the metadata DB directly
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_dev" {
  name             = "AllowDevIP"
  server_id        = azurerm_postgresql_flexible_server.airflow.id
  start_ip_address = var.allowed_source_ip
  end_ip_address   = var.allowed_source_ip
}
