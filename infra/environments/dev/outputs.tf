output "resource_group_name" {
  description = "Development platform resource group."
  value       = azurerm_resource_group.platform.name
}

output "virtual_network_id" {
  description = "Development virtual network ID."
  value       = module.network.virtual_network_id
}

output "node_subnet_id" {
  description = "Subnet reserved for future AKS nodes."
  value       = module.network.node_subnet_id
}

output "private_endpoint_subnet_id" {
  description = "Subnet reserved for possible future private endpoints; the demo does not create any."
  value       = module.network.private_endpoint_subnet_id
}

output "acr_id" {
  description = "Demo Azure Container Registry resource ID."
  value       = module.acr.id
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = module.acr.login_server
}

output "key_vault_id" {
  description = "Demo Key Vault resource ID."
  value       = module.key_vault.id
}

output "github_identity_client_id" {
  description = "Client ID for the GitHub OIDC identity; it has no Azure role grants in this foundation."
  value       = module.github_identity.client_id
}

output "github_identity_principal_id" {
  description = "Principal ID for a separately reviewed, narrowly scoped role assignment."
  value       = module.github_identity.principal_id
}
