variable "name" {
  description = "Globally unique Azure Container Registry name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR names must contain 5-50 alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group containing the registry."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "public_network_access_enabled" {
  description = "Enable the public registry endpoint. Disabled by default for enterprise use."
  type        = bool
  default     = false
}

variable "allow_all_networks" {
  description = "Explicit demo-only exception permitting all networks on the public endpoint."
  type        = bool
  default     = false
}

variable "allowed_ipv4_cidrs" {
  description = "Approved IPv4 CIDRs for the registry public endpoint."
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
  description = "Tags applied to the registry."
  type        = map(string)
}
