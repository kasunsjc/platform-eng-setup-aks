output "storage_account_id" {
  description = "Resource ID of the Terraform state storage account."
  value       = azurerm_storage_account.state.id
}

output "storage_account_name" {
  description = "Name of the Terraform state storage account."
  value       = azurerm_storage_account.state.name
}

output "container_names" {
  description = "Private state containers created for bootstrap and development."
  value = {
    bootstrap = azurerm_storage_container.bootstrap.name
    dev       = azurerm_storage_container.dev.name
  }
}
