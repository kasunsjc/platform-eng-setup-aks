output "id" {
  description = "User-assigned identity resource ID."
  value       = azurerm_user_assigned_identity.github.id
}

output "client_id" {
  description = "Client ID used by the federated GitHub environment."
  value       = azurerm_user_assigned_identity.github.client_id
}

output "principal_id" {
  description = "Principal ID for future, narrowly scoped role assignments."
  value       = azurerm_user_assigned_identity.github.principal_id
}
