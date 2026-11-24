variable "subscription_id" {
  description = "Azure subscription containing the Terraform state resources."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant used for Azure authentication."
  type        = string
}

variable "authentication_method" {
  description = "Authentication for the AzureRM provider: cli for local bootstrap or oidc for a federated runner."
  type        = string
  default     = "cli"

  validation {
    condition     = contains(["cli", "oidc"], var.authentication_method)
    error_message = "authentication_method must be either cli or oidc."
  }
}

variable "resource_group_name" {
  description = "Name of the dedicated resource group for Terraform state."
  type        = string
}

variable "location" {
  description = "Azure region for the state resource group and storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique, lowercase 3-24 character storage account name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must contain 3-24 lowercase letters or digits."
  }
}

variable "replication_type" {
  description = "Storage redundancy selected for the state recovery and cost requirements."
  type        = string

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be a supported Azure Storage redundancy option."
  }
}

variable "retention_days" {
  description = "Blob and container soft-delete retention, selected to meet the state recovery policy."
  type        = number

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "retention_days must be between 1 and 365."
  }
}

variable "tags" {
  description = "Required organization tags for state resources."
  type        = map(string)
}
