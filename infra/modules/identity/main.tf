resource "azurerm_user_assigned_identity" "github" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "github_environment" {
  name                = "github-${var.github_environment}"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.github.id
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:environment:${var.github_environment}"
  audience            = ["api://AzureADTokenExchange"]
}
