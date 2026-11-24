variable "subscription_id" {
  description = "Azure subscription ID for the development environment."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "authentication_method" {
  description = "Authentication for the AzureRM provider: cli for local development or oidc for a federated runner."
  type        = string
  default     = "cli"

  validation {
    condition     = contains(["cli", "oidc"], var.authentication_method)
    error_message = "authentication_method must be either cli or oidc."
  }
}

variable "resource_group_name" {
  description = "Name of the development platform resource group."
  type        = string
}

variable "location" {
  description = "Azure region selected after service availability and quota review."
  type        = string
}

variable "name_prefix" {
  description = "Short lowercase prefix used for regional Azure resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.name_prefix))
    error_message = "name_prefix must contain 2-8 lowercase letters or digits."
  }
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name."
  type        = string
}

variable "key_vault_name" {
  description = "Globally unique Key Vault name."
  type        = string
}

variable "github_repository" {
  description = "Repository in owner/name form that may request the federated token."
  type        = string
}

variable "github_environment" {
  description = "Protected GitHub environment trusted by the federated identity."
  type        = string
}

variable "vnet_address_space" {
  description = "Non-overlapping VNet CIDR blocks approved for the environment."
  type        = list(string)
}

variable "node_subnet_address_prefixes" {
  description = "Non-overlapping CIDRs reserved for future AKS nodes."
  type        = list(string)
}

variable "private_endpoint_subnet_address_prefixes" {
  description = "Non-overlapping CIDRs reserved for private endpoints."
  type        = list(string)
}

variable "tags" {
  description = "Required organization tags, such as cost center and owner."
  type        = map(string)
}
