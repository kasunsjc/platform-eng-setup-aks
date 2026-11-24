output "virtual_network_id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "node_subnet_id" {
  description = "Subnet resource ID reserved for future AKS nodes."
  value       = azurerm_subnet.nodes.id
}

output "private_endpoint_subnet_id" {
  description = "Subnet resource ID for private endpoints."
  value       = azurerm_subnet.private_endpoints.id
}
