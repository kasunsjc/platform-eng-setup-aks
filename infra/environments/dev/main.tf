locals {
  tags = merge(var.tags, {
    environment = "dev"
    managed_by  = "terraform"
  })

  name_prefix = "${var.name_prefix}-dev"
}

resource "azurerm_resource_group" "platform" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"

  name                                     = "vnet-${local.name_prefix}"
  location                                 = var.location
  resource_group_name                      = azurerm_resource_group.platform.name
  address_space                            = var.vnet_address_space
  node_subnet_name                         = "snet-aks-nodes"
  node_subnet_address_prefixes             = var.node_subnet_address_prefixes
  private_endpoint_subnet_name             = "snet-private-endpoints"
  private_endpoint_subnet_address_prefixes = var.private_endpoint_subnet_address_prefixes
  tags                                     = local.tags
}

module "acr" {
  source = "../../modules/acr"

  name                          = var.acr_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.platform.name
  public_network_access_enabled = true
  allow_all_networks            = true
  tags                          = local.tags
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.platform.name
  tenant_id                     = var.tenant_id
  public_network_access_enabled = true
  allow_all_networks            = true
  tags                          = local.tags
}

module "github_identity" {
  source = "../../modules/identity"

  name                = "id-${local.name_prefix}-github"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  github_repository   = var.github_repository
  github_environment  = var.github_environment
  tags                = local.tags
}
