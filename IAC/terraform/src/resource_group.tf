# Resource Group — container for all Web App resources (App Service, SQL, Key Vault)
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
