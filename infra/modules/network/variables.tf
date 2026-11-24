variable "name" {
  description = "Virtual network name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the virtual network."
  type        = string
}

variable "address_space" {
  description = "CIDR address spaces allocated to the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one virtual network CIDR is required."
  }
}

variable "node_subnet_name" {
  description = "Subnet reserved for future AKS nodes."
  type        = string
}

variable "node_subnet_address_prefixes" {
  description = "CIDR prefixes reserved for future AKS nodes."
  type        = list(string)

  validation {
    condition     = length(var.node_subnet_address_prefixes) > 0
    error_message = "At least one node subnet CIDR is required."
  }
}

variable "private_endpoint_subnet_name" {
  description = "Subnet for private endpoints."
  type        = string
}

variable "private_endpoint_subnet_address_prefixes" {
  description = "CIDR prefixes reserved for private endpoints."
  type        = list(string)

  validation {
    condition     = length(var.private_endpoint_subnet_address_prefixes) > 0
    error_message = "At least one private endpoint subnet CIDR is required."
  }
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
}
