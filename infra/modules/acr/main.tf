resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = "None"
  tags                          = var.tags

  network_rule_set {
    default_action = var.allow_all_networks ? "Allow" : "Deny"

    ip_rule = [for cidr in var.allowed_ipv4_cidrs : {
      action   = "Allow"
      ip_range = cidr
    }]
  }

  lifecycle {
    precondition {
      condition     = !var.public_network_access_enabled || var.allow_all_networks || length(var.allowed_ipv4_cidrs) > 0
      error_message = "Public registry access requires approved IPv4 CIDRs or explicit allow_all_networks."
    }
  }
}
