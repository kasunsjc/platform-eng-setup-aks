variable "name" {
  description = "Name of the user-assigned identity for the GitHub environment."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the identity."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/name form."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form."
  }
}

variable "github_environment" {
  description = "Protected GitHub environment name trusted by this identity."
  type        = string
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
}
