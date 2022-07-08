# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "location" {
  description = "The region for spoke network deployment"
  type        = string
}

variable "flow_log_storage_id" {
  type      = string
  default   = null
  sensitive = true
}

variable "laws_location" {
  description = "Log Analytics Workspace location"
  type        = string
}

variable "laws_workspace_id" {
  description = "Log Analytics Workspace workspace ID"
  type        = string
  sensitive   = true
}

variable "laws_resource_id" {
  description = "Log Analytics Workspace Azure Resource ID"
  type        = string
  sensitive   = true
}

variable "firewall_private_ip" {
  description = "Private IP of the Firewall"
  type        = string
  sensitive   = true
}

variable "spoke_rgname" {
  description = "Resource Group for the spoke network deployment"
  type        = string
}

variable "spoke_vnetname" {
  description = "Virtual Network Name for the spoke network deployment"
  type        = string
}

# Param Key Vault

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
  default     = "public"
}

variable "metadata_host" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
  type        = string
  default     = "management.azure.com"
}

variable "tier1_subid" {
  description = "Subscription ID for the Tier 1 deployment"
  type        = string
  sensitive   = true
}

variable "terraform_key_vault_name" {
  description = "Name of the Params Key Vault"
  type        = string
  sensitive   = true
}

variable "terraform_key_vault_rg" {
  description = "RG Name of the Params Key Vault"
  type        = string
}

variable "param_secret_prefix" {
  description = "Prefix for secrets in the Params Key Vault"
  type        = string
  sensitive   = true
  default     = null
}

#################################
# Network configuration section
#################################
variable "spoke_vnet_address_space" {
  description = "Address space prefixes for the spoke network"
  type        = list(string)
  sensitive   = true
}

variable "subnets" {
  description = "A complex object that describes subnets for the spoke network"
  type = map(object({
    name              = string
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    default_nsg_rules = list(string)
    nsg_rules         = list(string)
  }))
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

# Diagnostic Setting Variables
variable "eventhub_namespace_authorization_rule_id" {
  description = "Event Hub Authorization Rule to use for diagnostic settings."
  type        = string
  default     = null
  sensitive   = true
}

variable "eventhub_name" {
  description = "Event Hub Name to use for diagnostic settings."
  type        = string
  default     = null
}
