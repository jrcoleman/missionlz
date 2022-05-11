variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "identity_name" {
  description = "Name of the user assigned identity for the cmk key vault."
  type = string
}

variable "kv_name" {
  description = "Name of the key vault."
  type = string
  sensitive = true
}

variable "tenant_id" {
  type = string
  sensitive = true
}

variable "tags" {}