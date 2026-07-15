# Airflow VM — Docker Compose host running the webserver, scheduler and worker
resource "azurerm_linux_virtual_machine" "airflow" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size

  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.vm.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.vm_os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  # Installs Docker Engine + the Compose plugin, then renders and starts
  # docker-compose.yml (webserver/scheduler on LocalExecutor), wired
  # to the Postgres metadata DB via the Key Vault secret and syncing
  # dags/tasks/logs against Blob Storage using the VM's managed identity.
  custom_data = base64encode(templatefile("${path.module}/../install_docker.sh", {
    admin_username         = var.vm_admin_username
    key_vault_name         = var.key_vault_name
    postgres_secret_name   = "airflow-postgres-connection-string"
    storage_account_name   = var.storage_account_name
    dags_container_name    = var.dags_container_name
    logs_container_name    = var.logs_container_name
    docker_compose_content = file("${path.module}/../../../docker-compose.yml")
  }))

  tags = var.tags
}
