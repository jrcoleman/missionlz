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
  description = "The metadata host for the Azure Cloud e.g. management.azure.com or management.usgovcloudapi.net."
  type        = string
  default     = "management.azure.com"
}

variable "location" {
  description = "The Azure region for most Mission LZ resources. e.g. for government usgovvirginia"
  type        = string
  default     = "East US"
}

variable "resourcePrefix" {
  description = "A name for the deployment. It defaults to mlz."
  type        = string
}

variable "resourceSuffix" {
  description = "Suffix for resource names."
  type        = string
  default     = "mlz"
}

variable "tags" {
  description = "A map of key value pairs to apply as tags to resources provisioned in this deployment"
  type        = map(string)
  default = {
    "DeploymentType" : "MissionLandingZoneTF"
  }
}

variable "flow_log_storage_id" {
  description = "Storage account to ship nsg flow logs to"
  type        = string
  default     = null
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
# Hub Configuration
#################################

variable "hub_subid" {
  description = "Subscription ID for the Hub deployment"
  type        = string
  sensitive   = true
}

variable "hub_short_name" {
  description = "Short name of Hub Sub for templates."
  type        = string
  default     = "hub"
}

variable "hub_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "hub"
}

variable "hub_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vnet-hub"
}

variable "hub_vnet_address_space" {
  description = "The address space to be used for the virtual network."
  type        = list(string)
  default     = ["10.0.100.0/24"]
  sensitive   = true
}

variable "hub_subnets" {
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
    "hubSubnet" = {
      name              = "hubSubnet"
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      default_nsg_rules = ["DenyHighRisk", "AllowNIHNetIn", "AllowNIHNetOut"]
      nsg_rules         = []
    }
  }
}


#################################
# Firewall configuration section
#################################

variable "create_firewall" {
  description = "Create a firewall?"
  type        = bool
  default     = true
}

variable "custom_firewall_ip" {
  description = "IP address of customer firewall solution."
  default     = ""
  type        = string
}

variable "hub_client_address_space" {
  description = "The address space to be used for the Firewall virtual network."
  type        = string
  default     = "10.0.100.0/26"
  sensitive   = true
}

variable "hub_management_address_space" {
  description = "The address space to be used for the Firewall virtual network subnet used for management traffic."
  type        = string
  default     = "10.0.100.64/26"
  sensitive   = true
}

variable "firewall_name" {
  description = "Name of the Hub Firewall"
  type        = string
  default     = "firewall"
}

variable "firewall_sku_name" {
  description = "SKU name of the Firewall. Possible values are AZFW_Hub and AZFW_VNet."
  type        = string
  default     = "AZFW_VNet"
}

variable "firewall_policy_name" {
  description = "Name of the firewall policy to apply to the hub firewall"
  type        = string
  default     = "firewall-policy"
}

variable "client_ipconfig_name" {
  description = "The name of the Firewall Client IP Configuration"
  type        = string
  default     = "firewall-client-ip-config"
}

variable "client_publicip_name" {
  description = "The name of the Firewall Client Public IP"
  type        = string
  default     = "firewall-client-public-ip"
}

variable "management_ipconfig_name" {
  description = "The name of the Firewall Management IP Configuration"
  type        = string
  default     = "firewall-management-ip-config"
}

variable "management_publicip_name" {
  description = "The name of the Firewall Management Public IP"
  type        = string
  default     = "firewall-management-public-ip"
}

#################################
# Bastion Host Configuration
#################################

variable "create_bastion_jumpbox" {
  description = "Create a bastion host and jumpbox VM?"
  type        = bool
  default     = true
}

variable "bastion_host_name" {
  description = "The name of the Bastion Host"
  type        = string
  default     = "bastionHost"
}

variable "bastion_address_space" {
  description = "The address space to be used for the Bastion Host subnet (must be /27 or larger)."
  type        = string
  default     = "10.0.100.128/27"
  sensitive   = true
}

variable "bastion_public_ip_name" {
  description = "The name of the Bastion Host Public IP"
  type        = string
  default     = "bastionHostPublicIPAddress"
}

variable "bastion_ipconfig_name" {
  description = "The name of the Bastion Host IP Configuration"
  type        = string
  default     = "bastionHostIPConfiguration"
}

#################################
# Jumpbox VM Configuration
#################################

variable "jumpbox_subnet" {
  description = "The subnet for jumpboxes"
  type = object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    private_endpoint_network_policies_enabled     = bool
    private_link_service_network_policies_enabled = bool

    nsg_name = string
    nsg_rules = map(object({
      name                         = string
      priority                     = string
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_ranges           = list(string)
      destination_port_ranges      = list(string)
      source_address_prefixes      = list(string)
      destination_address_prefixes = list(string)
    }))

    routetable_name = string
  })
  default = {
    name              = "jumpbox-subnet"
    address_prefixes  = ["10.0.100.160/27"]
    service_endpoints = ["Microsoft.Storage"]

    private_endpoint_network_policies_enabled     = false
    private_link_service_network_policies_enabled = false

    nsg_name = "jumpbox-subnet-nsg"
    nsg_rules = {
      "allow_ssh" = {
        name                         = "allow_ssh"
        priority                     = "100"
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_ranges           = ["22"]
        destination_port_ranges      = ["*"]
        source_address_prefixes      = ["*"]
        destination_address_prefixes = ["*"]
      },
      "allow_rdp" = {
        name                         = "allow_rdp"
        priority                     = "200"
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_ranges           = ["3389"]
        destination_port_ranges      = ["*"]
        source_address_prefixes      = ["*"]
        destination_address_prefixes = ["*"]
      }
    }

    routetable_name = "jumpbox-routetable"
  }
}

variable "jumpbox_keyvault_name" {
  description = "The name of the jumpbox virtual machine keyvault"
  type        = string
  default     = "jumpboxKeyvault"
}

variable "jumpbox_windows_vm_name" {
  description = "The name of the Windows jumpbox virtual machine"
  type        = string
  default     = "jumpboxWindowsVm"
}

variable "jumpbox_windows_vm_size" {
  description = "The size of the Windows jumpbox virtual machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "jumpbox_windows_vm_publisher" {
  description = "The publisher of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "jumpbox_windows_vm_offer" {
  description = "The offer of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "WindowsServer"
}

variable "jumpbox_windows_vm_sku" {
  description = "The SKU of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "2019-datacenter-gensecond"
}

variable "jumpbox_windows_vm_version" {
  description = "The version of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "latest"
}

variable "jumpbox_linux_vm_name" {
  description = "The name of the Linux jumpbox virtual machine"
  type        = string
  default     = "jumpboxLinuxVm"
}

variable "jumpbox_linux_vm_size" {
  description = "The size of the Linux jumpbox virtual machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "jumpbox_linux_vm_publisher" {
  description = "The publisher of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "Canonical"
}

variable "jumpbox_linux_vm_offer" {
  description = "The offer of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "UbuntuServer"
}

variable "jumpbox_linux_vm_sku" {
  description = "The SKU of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "18.04-LTS"
}

variable "jumpbox_linux_vm_version" {
  description = "The version of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "latest"
}

################################
# Policy Configuration
################################

variable "create_policy_assignment" {
  description = "Assign Policy to deployed resources?"
  type        = bool
  default     = false
}

#################################
# Tier 0 Configuration
#################################

variable "tier0_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tier0_short_name" {
  description = "Short name of Tier0 Sub for templates."
  type        = string
  default     = "tier0"
}

variable "tier0_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "identity"
}

variable "tier0_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vnet-identity"
}

variable "tier0_vnet_address_space" {
  description = "Address space prefixes list of strings"
  type        = list(string)
  default     = ["10.0.110.0/26"]
  sensitive   = true
}

variable "tier0_subnets" {
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
    "identitySubnet" = {
      name              = "identitySubnet"
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      default_nsg_rules = ["DenyHighRisk", "AllowNIHNetIn", "AllowNIHNetOut"]
      nsg_rules         = []
    }
  }
}

#################################
# Tier 1 Configuration
#################################

variable "tier1_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tier1_short_name" {
  description = "Short name of Tier 1 Sub for templates."
  type        = string
  default     = "tier1"
}

variable "tier1_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "operations"
}

variable "tier1_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vnet-operations"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace Name for the deployment"
  type        = string
  default     = "log-operations"
}

variable "create_sentinel" {
  description = "Create an Azure Sentinel Log Analytics Workspace Solution"
  type        = bool
  default     = true
}

variable "tier1_vnet_address_space" {
  description = "Address space prefixes for the virtual network"
  type        = list(string)
  default     = ["10.0.115.0/26"]
  sensitive   = true
}

variable "tier1_subnets" {
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
    "operationsSubnet" = {
      name              = "operationsSubnet"
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      default_nsg_rules = ["DenyHighRisk", "AllowNIHNetIn", "AllowNIHNetOut"]
      nsg_rules         = []
    }
  }
}

#################################
# Tier 2 Configuration
#################################

variable "tier2_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tier2_short_name" {
  description = "Short name of Tier 2 Sub for templates."
  type        = string
  default     = "tier2"
}

variable "tier2_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "sharedServices"
}

variable "tier2_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vnet-sharedServices"
}

variable "tier2_vnet_address_space" {
  description = "Address space prefixes list of strings"
  type        = list(string)
  default     = ["10.0.120.0/26"]
  sensitive   = true
}

variable "tier2_subnets" {
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
    "sharedServicesSubnet" = {
      name              = "sharedServicesSubnet"
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      default_nsg_rules = ["DenyHighRisk", "AllowNIHNetIn", "AllowNIHNetOut"]
      nsg_rules         = []
    }
  }
}

# Diagnostic Setting Variables
variable "eventhub_namespace_authorization_rule_id" {
  description = "Event Hub Authorization Rule to use for diagnostic settings."
  type        = string
  default     = null
  sensitive   = true
}

variable "eventhub_name_activity" {
  description = "Event Hub Name to use for insights actvity."
  type        = string
  default     = null
}

variable "eventhub_name_logs" {
  description = "Event Hub Name to use for logs."
  type        = string
  default     = null
}
