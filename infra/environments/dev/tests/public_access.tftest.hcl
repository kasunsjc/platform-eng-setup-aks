mock_provider "azurerm" {}

run "demo_root_accepts_public_networks" {
  command = plan

  variables {
    subscription_id                          = "00000000-0000-0000-0000-000000000000"
    tenant_id                                = "00000000-0000-0000-0000-000000000000"
    resource_group_name                      = "demo-platform"
    location                                 = "westeurope"
    name_prefix                              = "demo"
    acr_name                                 = "demoregistry"
    key_vault_name                           = "demo-vault"
    github_repository                        = "example/demo"
    github_environment                       = "demo"
    vnet_address_space                       = ["10.0.0.0/16"]
    node_subnet_address_prefixes             = ["10.0.0.0/24"]
    private_endpoint_subnet_address_prefixes = ["10.0.1.0/24"]
    tags                                     = {}
  }
}

run "registry_demo_allows_public_networks" {
  command = plan

  module {
    source = "../../modules/acr"
  }

  variables {
    name                          = "demoregistry"
    resource_group_name           = "demo"
    location                      = "westeurope"
    public_network_access_enabled = true
    allow_all_networks            = true
    tags                          = {}
  }

  assert {
    condition     = azurerm_container_registry.this.public_network_access_enabled && azurerm_container_registry.this.network_rule_set[0].default_action == "Allow" && !azurerm_container_registry.this.admin_enabled
    error_message = "Demo registry must allow public networks without enabling admin credentials."
  }
}

run "vault_demo_allows_public_networks" {
  command = plan

  module {
    source = "../../modules/key-vault"
  }

  variables {
    name                          = "demo-vault"
    resource_group_name           = "demo"
    location                      = "westeurope"
    tenant_id                     = "00000000-0000-0000-0000-000000000000"
    public_network_access_enabled = true
    allow_all_networks            = true
    tags                          = {}
  }

  assert {
    condition     = azurerm_key_vault.this.public_network_access_enabled && azurerm_key_vault.this.network_acls[0].default_action == "Allow" && azurerm_key_vault.this.rbac_authorization_enabled
    error_message = "Demo vault must allow public networks while retaining Entra RBAC."
  }
}

run "registry_rejects_unrestricted_access" {
  command = plan

  module {
    source = "../../modules/acr"
  }

  variables {
    name                          = "demoregistry"
    resource_group_name           = "demo"
    location                      = "westeurope"
    public_network_access_enabled = true
    allowed_ipv4_cidrs            = ["0.0.0.0/0"]
    tags                          = {}
  }

  expect_failures = [var.allowed_ipv4_cidrs]
}

run "vault_rejects_empty_allowlist" {
  command = plan

  module {
    source = "../../modules/key-vault"
  }

  variables {
    name                          = "demo-vault"
    resource_group_name           = "demo"
    location                      = "westeurope"
    tenant_id                     = "00000000-0000-0000-0000-000000000000"
    public_network_access_enabled = true
    tags                          = {}
  }

  expect_failures = [azurerm_key_vault.this]
}

run "registry_is_private_by_default" {
  command = plan

  module {
    source = "../../modules/acr"
  }

  variables {
    name                = "demoregistry"
    resource_group_name = "demo"
    location            = "westeurope"
    tags                = {}
  }

  assert {
    condition     = !azurerm_container_registry.this.public_network_access_enabled
    error_message = "Reusable registry module must default to private access."
  }
}

run "vault_is_private_by_default" {
  command = plan

  module {
    source = "../../modules/key-vault"
  }

  variables {
    name                = "demo-vault"
    resource_group_name = "demo"
    location            = "westeurope"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
    tags                = {}
  }

  assert {
    condition     = !azurerm_key_vault.this.public_network_access_enabled
    error_message = "Reusable vault module must default to private access."
  }
}
