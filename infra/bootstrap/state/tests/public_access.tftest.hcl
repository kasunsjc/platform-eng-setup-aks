mock_provider "azurerm" {}

variables {
  subscription_id      = "00000000-0000-0000-0000-000000000000"
  tenant_id            = "00000000-0000-0000-0000-000000000000"
  resource_group_name  = "demo-state"
  location             = "westeurope"
  storage_account_name = "demostate123"
  replication_type     = "LRS"
  retention_days       = 30
  tags                 = {}
}

run "state_demo_allows_public_networks" {
  command = plan

  assert {
    condition     = azurerm_storage_account.state.public_network_access_enabled && azurerm_storage_account.state.network_rules[0].default_action == "Allow" && !azurerm_storage_account.state.shared_access_key_enabled && !azurerm_storage_account.state.allow_nested_items_to_be_public
    error_message = "Demo state must allow public networks without enabling shared keys or public blobs."
  }
}
