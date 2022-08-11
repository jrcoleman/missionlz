# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#################################
# Global Configuration
#################################

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

variable "location" {
  description = "The Azure region for most Mission LZ resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "A map of key value pairs to apply as tags to resources provisioned in this deployment"
  type        = map(string)
  default = {
    "DeploymentType" : "MissionLandingZoneTF"
  }
}

#################################
# Hub Configuration
#################################

variable "hub_subid" {
  description = "Subscription ID for the Hub deployment"
  type        = string
  sensitive   = true
}

variable "hub_rgname" {
  description = "Resource Group for the Hub deployment"
  type        = string
}

variable "hub_vnetname" {
  description = "Virtual Network Name for the Hub deployment"
  type        = string
}

variable "firewall_private_ip" {
  description = "Firewall IP to bind network to"
  type        = string
  sensitive   = true
}

#################################
# Tier 1 Configuration
#################################

variable "tier1_subid" {
  description = "Subscription ID for the Tier 1 deployment"
  type        = string
  sensitive   = true
}

variable "laws_name" {
  description = "Log Analytics Workspace Name for the deployment"
  type        = string
}

variable "laws_rgname" {
  description = "The resource group that Log Analytics Workspace was deployed to"
  type        = string
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


#################################
# Tier 3 Configuration
#################################
variable "short_name" {
  description = "Short name for the tier3 deployment"
  type        = string
}

variable "tier3_subid" {
  description = "Subscription ID for this Tier 3 deployment"
  type        = string
  sensitive   = true
}

variable "tier3_rgname" {
  description = "Resource Group for this Tier 3 deployment"
  type        = string
  default     = "tier3-rg"
}

variable "tier3_rg_exemptions" {
  description = "List of Policy Assignments to exempt the resource group from."
  type        = list(string)
  default     = []
}

variable "tier3_vnetname" {
  description = "Virtual Network Name for this Tier 3 deployment"
  type        = string
  default     = "tier3-vnet"
}

variable "tier3_vnet_address_space" {
  description = "Address space prefixes list of strings"
  type        = list(string)
  default     = ["10.0.125.0/26"]
  sensitive   = true
}

variable "tier3_subnets" {
  description = "A complex object that describes subnets."
  type = map(object({
    name              = string
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    default_nsg_rules = list(string)
    nsg_rules         = list(string)
  }))
  default = {
    "tier3subnet" = {
      name              = "tier3Subnet"
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false
      default_nsg_rules                              = ["DenyHighRisk", "AllowNIHNetIn", "AllowNIHNetOut"]
      nsg_rules                                      = []
    }
  }
}

# Flow Log Storage Account
variable "flow_log_storage_id" {
  description = "Storage account to ship nsg flow logs to"
  type        = string
  default     = null
}
