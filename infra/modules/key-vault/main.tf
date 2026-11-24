resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  network_acls {
    bypass         = "None"
    default_action = var.allow_all_networks ? "Allow" : "Deny"
    ip_rules       = var.allowed_ipv4_cidrs
  }

  lifecycle {
    precondition {
      condition     = !var.public_network_access_enabled || var.allow_all_networks || length(var.allowed_ipv4_cidrs) > 0
      error_message = "Public Key Vault access requires approved IPv4 CIDRs or explicit allow_all_networks."
    }
  }
}
