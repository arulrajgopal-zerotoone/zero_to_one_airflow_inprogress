# common variables
variable "tags" {
  type        = map(string)
  description = "Tags to be applied to all resources"
  default = {
    ManagedBy   = "Terraform"
    Application = "AirflowDataPipeline"
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "South India"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Resource Group that contains all Airflow infrastructure"
}


# networking
variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
  default     = "vnet-airflow"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network"
  default     = ["10.10.0.0/16"]
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet hosting the Airflow VM"
  default     = "snet-airflow"
}

variable "subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the Airflow VM subnet"
  default     = ["10.10.1.0/24"]
}

variable "nsg_name" {
  type        = string
  description = "Name of the Network Security Group protecting the Airflow VM"
  default     = "nsg-airflow"
}

variable "allowed_source_ip" {
  type        = string
  description = "Single IP address allowed to reach the Airflow VM over SSH (22) and the webserver UI (443/8080), and the Postgres metadata DB. Use the developer's own IP only — never a broad range or 0.0.0.0/0."
}


# VM (Docker Compose host: webserver + scheduler + worker)
variable "vm_name" {
  type        = string
  description = "Name of the Airflow VM"
  default     = "vm-airflow"
}

variable "vm_size" {
  type        = string
  description = "VM size for the Airflow host"
  default     = "Standard_D2s_v3"
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for the Airflow VM"
}

variable "vm_admin_password" {
  type        = string
  description = "Admin password for the Airflow VM's admin user (SSH key auth is disabled)"
  sensitive   = true
}

variable "vm_os_disk_size_gb" {
  type        = number
  description = "OS disk size (GB) for the Airflow VM"
  default     = 64
}


# Azure Database for PostgreSQL Flexible Server (Airflow metadata DB)
variable "postgres_server_name" {
  type        = string
  description = "Name of the PostgreSQL Flexible Server (must be globally unique). Pass via TF_VAR_postgres_server_name."
}

variable "postgres_database_name" {
  type        = string
  description = "Name of the Airflow metadata database. Pass via TF_VAR_postgres_database_name."
}

variable "postgres_data_database_name" {
  type        = string
  description = "Name of the secondary (data) database. Pass via TF_VAR_postgres_data_database_name."
}

variable "postgres_admin_username" {
  type        = string
  description = "Administrator username for PostgreSQL Flexible Server"
}

variable "postgres_admin_password" {
  type        = string
  description = "Administrator password for PostgreSQL Flexible Server"
  sensitive   = true
}

variable "postgres_sku_name" {
  type        = string
  description = "SKU for the PostgreSQL Flexible Server (Burstable tier is enough for this workload)"
  default     = "B_Standard_B1ms"
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL major version"
  default     = "16"
}

variable "postgres_storage_mb" {
  type        = number
  description = "Storage size (MB) for the PostgreSQL Flexible Server"
  default     = 32768
}


# Azure Blob Storage (DAG files + task logs)
variable "storage_account_name" {
  type        = string
  description = "Name of the Storage Account for DAGs/logs (lowercase alphanumeric, 3-24 chars, globally unique)"
}

variable "dags_container_name" {
  type        = string
  description = "Blob container holding DAG files synced to the VM"
  default     = "dags"
}

variable "logs_container_name" {
  type        = string
  description = "Blob container holding Airflow task logs"
  default     = "logs"
}


# Key Vault
variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault (must be globally unique, 3-24 chars)"
}


# creds
variable "tenant_id" {
  type    = string
  default = "XXXX"
}

variable "subscription_id" {
  type    = string
  default = "XXXX"
}

variable "client_id" {
  type    = string
  default = "XXXX"
}

variable "client_secret" {
  type      = string
  sensitive = true
  default   = "XXXX"
}
