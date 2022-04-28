# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "create_firewall" {
  type = bool
  default = true
}

variable "create_log_storage" {
  type = bool
  default = true
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space to be used for the virtual network."
  default     = []
  type        = list(string)
}

variable "subnets" {
  description = "A complex object that describes subnets for the spoke network"
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    nsg_name = string
    nsg_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

    routetable_name = string
  }))
}

variable "client_address_space" {
  description = "The address space to be used for the Firewall virtual network subnet used for client traffic."
  type        = string
}

variable "management_address_space" {
  description = "The address space to be used for the Firewall virtual network subnet used for management traffic."
  type        = string
}

variable "log_analytics_workspace_resource_id" {
  description = "The Azure resource ID for the Log Analytics Workspace."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map(string)
}
