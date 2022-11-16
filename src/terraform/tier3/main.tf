# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

// Default subscription is tier 1. Be specific for other subscriptions.
provider "azurerm" {
  environment     = var.environment
  metadata_host   = var.metadata_host
  subscription_id = var.tier1_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azurerm" {
  alias           = "hub"
  environment     = var.environment
  metadata_host   = var.metadata_host
  subscription_id = var.hub_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azurerm" {
  alias           = "tier1"
  environment     = var.environment
  metadata_host   = var.metadata_host
  subscription_id = var.tier1_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azurerm" {
  alias           = "tier3"
  environment     = var.environment
  metadata_host   = var.metadata_host
  subscription_id = var.tier3_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

################################
### STAGE 0: Scaffolding     ###
################################

resource "azurerm_resource_group" "tier3" {
  provider = azurerm.tier3

  location = var.location
  name     = var.tier3_rgname
  tags     = var.tags
}

resource "azurerm_resource_group_policy_exemption" "exempt" {
  for_each             = toset(var.tier3_rg_exemptions)
  name                 = "${var.short_name}-exemption-${index(var.tier3_rg_exemptions, each.value)}"
  resource_group_id    = azurerm_resource_group.tier3.id
  policy_assignment_id = each.value
  exemption_category   = "Waiver"
}

################################
### STAGE 1: Logging         ###
################################

data "azurerm_log_analytics_workspace" "laws" {
  provider = azurerm.tier1

  name                = var.laws_name
  resource_group_name = var.laws_rgname
}

################################
### STAGE 2: Networking      ###
################################

data "azurerm_virtual_network" "hub" {
  provider = azurerm.hub

  name                = var.hub_vnetname
  resource_group_name = var.hub_rgname
}

module "spoke-network-t3" {
  count = length(var.tier3_vnet_address_space) == 0 ? 0 : 1
  providers = {
    azurerm       = azurerm.tier3
    azurerm.tier1 = azurerm.tier1
  }
  depends_on = [azurerm_resource_group.tier3, azurerm_resource_group_policy_exemption.exempt]
  source     = "../modules/spoke"

  environment              = var.environment
  metadata_host            = var.metadata_host
  tier1_subid              = var.tier1_subid
  terraform_key_vault_name = var.terraform_key_vault_name
  terraform_key_vault_rg   = var.terraform_key_vault_rg
  param_secret_prefix      = lower(var.short_name)

  location = azurerm_resource_group.tier3.location

  firewall_private_ip = var.firewall_private_ip

  laws_location       = var.location
  laws_workspace_id   = sensitive(data.azurerm_log_analytics_workspace.laws.workspace_id)
  laws_resource_id    = sensitive(data.azurerm_log_analytics_workspace.laws.id)
  flow_log_storage_id = var.flow_log_storage_id

  spoke_rgname             = azurerm_resource_group.tier3.name
  spoke_vnetname           = var.tier3_vnetname
  spoke_vnet_address_space = var.tier3_vnet_address_space
  subnets                  = var.tier3_subnets
  tags                     = var.tags
}

# JC Note: Re enable gateway transit once ExpressRoute Gateway is present.
resource "azurerm_virtual_network_peering" "t3-to-hub" {
  count      = length(var.tier3_vnet_address_space) == 0 ? 0 : 1
  provider   = azurerm.tier3
  depends_on = [azurerm_resource_group.tier3, module.spoke-network-t3]

  name                         = "${var.tier3_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = var.tier3_rgname
  virtual_network_name         = var.tier3_vnetname
  remote_virtual_network_id    = sensitive(data.azurerm_virtual_network.hub.id)
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "hub-to-t3" {
  count      = length(var.tier3_vnet_address_space) == 0 ? 0 : 1
  provider   = azurerm.hub
  depends_on = [module.spoke-network-t3]

  name                         = "${var.hub_vnetname}-to-${var.tier3_vnetname}"
  resource_group_name          = var.hub_rgname
  virtual_network_name         = var.hub_vnetname
  remote_virtual_network_id    = module.spoke-network-t3[0].virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}
