
variable "name" {
  description = "Name to insert in naming conventions."
  type = string
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
  sensitive = true
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
  sensitive = true
}

variable "vnet_id" {
  type = string
  sensitive = true
}

variable "tags" {}
