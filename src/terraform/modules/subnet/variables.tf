# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# All Resources

variable "name" {
  description = "The name of the subnet"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the subnet's resource group"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
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

# NSG

variable "default_nsg_rules" {
  description = "List of default nsg rules to include from the Params Key Vault"
  type        = list(string)
  default     = ["DenyHighRisk", "AllowNIHNetIn", "AllowNIHNetOut"]
}

variable "nsg_rules" {
  description = "List of nsg rule names to retrieve from the param key vault."
  type        = list(string)
  default     = []
}

# Subnet

variable "virtual_network_name" {
  description = "The name of the subnet's virtual network"
  type        = string
}

variable "address_prefixes" {
  description = "The subnet address prefixes"
  type        = list(string)
  sensitive   = true
}

variable "service_endpoints" {
  description = "The service endpoints to optimize for this subnet"
  type        = list(string)
  default     = null
}

variable "enforce_private_link_endpoint_network_policies" {
  description = "Enforce Private Link Endpoints"
  type        = bool
  default     = false
}

variable "enforce_private_link_service_network_policies" {
  description = "Enforce Private Link Service"
  type        = bool
  default     = false
}


# Route Table

variable "firewall_ip_address" {
  description = "The IP Address of the Firewall"
  type        = string
}


# Logging

variable "log_analytics_storage_id" {
  description = "The id of the storage account that stores log analytics diagnostic logs"
  type        = string
  default     = null
  sensitive   = true
}

variable "flow_log_storage_id" {
  type      = string
  default   = null
  sensitive = true
}

variable "log_analytics_workspace_id" {
  description = "The id of the log analytics workspace"
  type        = string
}

variable "log_analytics_workspace_location" {
  description = "The location of the log analytics workspace"
  type        = string
}

variable "log_analytics_workspace_resource_id" {
  description = "The resource id of the log analytics workspace"
  type        = string
}

variable "flow_log_retention_in_days" {
  description = "The number of days to retain flow log data"
  default     = "90"
  type        = number
}

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
