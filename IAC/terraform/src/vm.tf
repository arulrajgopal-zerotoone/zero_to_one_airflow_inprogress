# Airflow VM — Docker Compose host running the webserver, scheduler and worker
resource "azurerm_linux_virtual_machine" "airflow" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size

  admin_username                  = var.vm_admin_username
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.vm.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_ssh_public_key
  }

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

  # Installs Docker Engine + the Compose plugin so `docker compose up` can run
  # the webserver/scheduler/worker stack from the project's docker-compose.yml
  custom_data = base64encode(templatefile("${path.module}/scripts/install_docker.sh", {
    admin_username = var.vm_admin_username
  }))

  tags = var.tags
}
