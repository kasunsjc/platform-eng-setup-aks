output "id" {
  description = "Container registry resource ID."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Container registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Container registry login server."
  value       = azurerm_container_registry.this.login_server
}
