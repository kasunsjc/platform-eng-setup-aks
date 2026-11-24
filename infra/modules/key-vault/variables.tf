variable "name" {
  description = "Globally unique Key Vault name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "Key Vault names must contain 3-24 alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the vault."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "public_network_access_enabled" {
  description = "Enable the public vault endpoint. Disabled by default for enterprise use."
  type        = bool
  default     = false
}

variable "allow_all_networks" {
  description = "Explicit demo-only exception permitting all networks on the public endpoint."
  type        = bool
  default     = false
}

variable "allowed_ipv4_cidrs" {
  description = "Approved IPv4 CIDRs for the vault public endpoint."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_ipv4_cidrs :
      can(regex("^[0-9.]+/[0-9]+$", cidr)) && can(cidrhost(cidr, 0)) && try(tonumber(split("/", cidr)[1]) > 0, false)
    ])
    error_message = "Use valid IPv4 CIDRs narrower than 0.0.0.0/0."
  }
}

variable "tags" {
  description = "Tags applied to the vault."
  type        = map(string)
}
