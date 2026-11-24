resource "azurerm_resource_group" "state" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                            = var.tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.retention_days
    }

    container_delete_retention_policy {
      days = var.retention_days
    }
  }

  network_rules {
    default_action = "Allow"
    bypass         = []
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "bootstrap" {
  name                  = "bootstrap"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "dev" {
  name                  = "dev"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
