resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = var.node_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.node_subnet_address_prefixes
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = var.private_endpoint_subnet_name
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = var.private_endpoint_subnet_address_prefixes
  private_endpoint_network_policies = "Disabled"
}
