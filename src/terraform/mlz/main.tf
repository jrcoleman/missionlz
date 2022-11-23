# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

// JC Note: Terraform and backend config handled by wrapper.
// terraform {
//   # It is recommended to use remote state instead of local
//   # If you are using Terraform Cloud, You can update these values in order to configure your remote state.
//   /*  backend "remote" {
//     organization = "{{ORGANIZATION_NAME}}"
//     workspaces {
//       name = "{{WORKSPACE_NAME}}"
//     }
//   }
//   */
//   backend "local" {}

//   required_version = ">= 1.0.11"
//   required_providers {
//     azurerm = {
//       source  = "hashicorp/azurerm"
//       version = "= 2.90.0"
//     }
//     random = {
//       source  = "hashicorp/random"
//       version = "= 3.1.0"
//     }
//     time = {
//       source  = "hashicorp/time"
//       version = "0.7.2"
//     }
//   }
// }

provider "azurerm" {
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
  alias           = "tier0"
  environment     = var.environment
  metadata_host   = var.metadata_host
  subscription_id = coalesce(var.tier0_subid, var.hub_subid)

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
  subscription_id = coalesce(var.tier1_subid, var.hub_subid)

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
  alias           = "tier2"
  environment     = var.environment
  metadata_host   = var.metadata_host
  subscription_id = coalesce(var.tier2_subid, var.hub_subid)

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "random" {
}

provider "time" {
}

data "azurerm_client_config" "current_client" {
}

################################
### GLOBAL VARIABLES         ###
################################

locals {
  firewall_premium_environments = ["public", "usgovernment"] # terraform azurerm environments where Azure Firewall Premium is supported
}

################################
### STAGE 0: Scaffolding     ###
################################
// resource "random_id" "random" {
//   keepers = {
//     # Generate a new id each time we change resourePrefix variable
//     resourcePrefix = var.resourcePrefix
//   }
//   byte_length = 8
// }

resource "azurerm_resource_group" "hub" {
  provider = azurerm.hub

  location = var.location
  name     = "${var.resourcePrefix}-rg-${var.hub_rgname}-${var.resourceSuffix}"
  tags     = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

resource "azurerm_resource_group" "tier0" {
  provider = azurerm.tier0

  location = var.location
  name     = "${var.resourcePrefix}-rg-${var.tier0_rgname}-${var.resourceSuffix}"
  tags     = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

resource "azurerm_resource_group" "tier1" {
  provider = azurerm.tier1

  location = var.location
  name     = "${var.resourcePrefix}-rg-${var.tier1_rgname}-${var.resourceSuffix}"
  tags     = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

resource "azurerm_resource_group" "tier2" {
  provider = azurerm.tier2

  location = var.location
  name     = "${var.resourcePrefix}-rg-${var.tier2_rgname}-${var.resourceSuffix}"
  tags     = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

################################
### STAGE 1: Logging         ###
################################

resource "azurerm_log_analytics_workspace" "laws" {
  provider = azurerm.tier1

  name                 = "${var.resourcePrefix}-${var.log_analytics_workspace_name}-${var.resourceSuffix}"
  resource_group_name  = azurerm_resource_group.tier1.name
  location             = var.location
  sku                  = "PerGB2018"
  cmk_for_query_forced = true
  retention_in_days    = "181"
  tags                 = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

resource "azurerm_log_analytics_solution" "laws_sentinel" {
  provider = azurerm.tier1
  count    = var.create_sentinel ? 1 : 0

  solution_name         = "SecurityInsights"
  location              = azurerm_resource_group.tier1.location
  resource_group_name   = azurerm_resource_group.tier1.name
  workspace_resource_id = azurerm_log_analytics_workspace.laws.id
  workspace_name        = azurerm_log_analytics_workspace.laws.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
  tags = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

# Central Logging
locals {
  log_categories = ["Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth"]
}

# JC Note: ignore_changes log set for diagnostic settings due to null bug
# JC Note: comment out ignore_changes to update diagnostic settings

resource "azurerm_monitor_diagnostic_setting" "hub-central" {
  provider           = azurerm.hub
  name               = "hub-central-diagnostics"
  target_resource_id = "/subscriptions/${var.hub_subid}"

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.laws.id
  eventhub_name                  = var.eventhub_name_activity
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  dynamic "log" {
    for_each = local.log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }
  lifecycle {
    ignore_changes = [
      log
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "tier0-central" {
  count              = (var.tier0_subid != "") ? (var.tier0_subid != var.hub_subid ? 1 : 0) : 0
  provider           = azurerm.tier0
  name               = "tier0-central-diagnostics"
  target_resource_id = "/subscriptions/${var.tier0_subid}"

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.laws.id
  eventhub_name                  = var.eventhub_name_activity
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  dynamic "log" {
    for_each = local.log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }
  lifecycle {
    ignore_changes = [
      log
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "tier1-central" {
  count              = (var.tier1_subid != "") ? (var.tier1_subid != var.hub_subid ? 1 : 0) : 0
  provider           = azurerm.tier1
  name               = "tier1-central-diagnostics"
  target_resource_id = "/subscriptions/${var.tier1_subid}"

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.laws.id
  eventhub_name                  = var.eventhub_name_activity
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  dynamic "log" {
    for_each = local.log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }
  lifecycle {
    ignore_changes = [
      log
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "tier2-central" {
  count              = (var.tier2_subid != "") ? (var.tier2_subid != var.hub_subid ? 1 : 0) : 0
  provider           = azurerm.tier2
  name               = "tier2-central-diagnostics"
  target_resource_id = "/subscriptions/${var.tier2_subid}"

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.laws.id
  eventhub_name                  = var.eventhub_name_activity
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  dynamic "log" {
    for_each = local.log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }
  lifecycle {
    ignore_changes = [
      log
    ]
  }
}

###############################
## STAGE 2: Networking      ###
###############################

module "hub-network" {
  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub]
  source     = "../modules/hub"

  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  vnet_name           = "${var.resourcePrefix}-${var.hub_vnetname}-${var.resourceSuffix}"
  vnet_address_space  = var.hub_vnet_address_space

  client_address_space     = var.hub_client_address_space
  management_address_space = var.hub_management_address_space
  create_firewall          = var.create_firewall

  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id
  tags                                = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

module "hub_subnet_params" {
  for_each = var.hub_subnets

  source    = "../modules/subnet-params"
  providers = { azurerm = azurerm.tier1 }

  terraform_key_vault_name = var.terraform_key_vault_name
  terraform_key_vault_rg   = var.terraform_key_vault_rg
  param_secret_prefix      = var.hub_short_name

  name              = each.value.name
  default_nsg_rules = each.value.default_nsg_rules
  nsg_rules         = each.value.nsg_rules
}

module "hub-subnets" {
  providers  = { azurerm = azurerm.hub }
  depends_on = [module.hub-network]
  source     = "../modules/subnet"
  for_each   = var.hub_subnets

  name                 = each.value.name
  location             = var.location
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = module.hub-network.virtual_network_name
  address_prefixes     = module.hub_subnet_params[each.key].address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", null)
  enforce_private_link_service_network_policies  = lookup(each.value, "enforce_private_link_service_network_policies", null)

  nsg_rules_names = concat(lookup(each.value, "default_nsg_rules", []), lookup(each.value, "nsg_rules", []))
  nsg_rules_map   = module.hub_subnet_params[each.key].nsg_rules

  # routetable_name     = each.value.routetable_name
  firewall_ip_address = var.create_firewall ? module.firewall[0].firewall_private_ip : var.custom_firewall_ip

  flow_log_storage_id = var.flow_log_storage_id
  # JC Note: Using centralized log storage
  # log_analytics_storage_id                 = module.hub-network.log_analytics_storage_id
  log_analytics_workspace_id               = azurerm_log_analytics_workspace.laws.workspace_id
  log_analytics_workspace_location         = var.location
  log_analytics_workspace_resource_id      = azurerm_log_analytics_workspace.laws.id
  eventhub_name                            = var.eventhub_name_logs
  eventhub_namespace_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  tags = var.tags
}

module "firewall" {
  count      = var.create_firewall ? 1 : 0
  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network]
  source     = "../modules/firewall"

  sub_id               = var.hub_subid
  resource_group_name  = module.hub-network.resource_group_name
  location             = var.location
  vnet_name            = module.hub-network.virtual_network_name
  vnet_address_space   = module.hub-network.virtual_network_address_space
  client_address_space = var.hub_client_address_space

  firewall_name                   = "${var.resourcePrefix}-${var.firewall_name}-${var.resourceSuffix}"
  firewall_sku_name               = var.firewall_sku_name
  firewall_sku                    = contains(local.firewall_premium_environments, lower(var.environment)) ? "Premium" : "Standard"
  firewall_client_subnet_name     = module.hub-network.firewall_client_subnet_name
  firewall_management_subnet_name = module.hub-network.firewall_management_subnet_name
  firewall_policy_name            = var.firewall_policy_name

  client_ipconfig_name = var.client_ipconfig_name
  client_publicip_name = var.client_publicip_name

  management_ipconfig_name = var.management_ipconfig_name
  management_publicip_name = var.management_publicip_name

  log_analytics_workspace_resource_id      = azurerm_log_analytics_workspace.laws.id
  eventhub_name                            = var.eventhub_name_logs
  eventhub_namespace_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  tags = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

module "spoke-network-t0" {
  providers = {
    azurerm       = azurerm.tier0
    azurerm.tier1 = azurerm.tier1
  }
  depends_on = [azurerm_resource_group.tier0, module.hub-network, module.firewall]
  source     = "../modules/spoke"

  environment              = var.environment
  metadata_host            = var.metadata_host
  tier1_subid              = var.tier1_subid
  terraform_key_vault_name = var.terraform_key_vault_name
  terraform_key_vault_rg   = var.terraform_key_vault_rg
  param_secret_prefix      = lower(var.tier0_short_name)

  location = azurerm_resource_group.tier0.location

  firewall_private_ip = var.create_firewall ? module.firewall[0].firewall_private_ip : var.custom_firewall_ip

  laws_location                            = var.location
  laws_workspace_id                        = azurerm_log_analytics_workspace.laws.workspace_id
  laws_resource_id                         = azurerm_log_analytics_workspace.laws.id
  eventhub_name                            = var.eventhub_name_logs
  eventhub_namespace_authorization_rule_id = var.eventhub_namespace_authorization_rule_id
  flow_log_storage_id                      = var.flow_log_storage_id

  spoke_rgname             = azurerm_resource_group.tier0.name
  spoke_vnetname           = "${var.resourcePrefix}-${var.tier0_vnetname}-${var.resourceSuffix}"
  spoke_vnet_address_space = var.tier0_vnet_address_space
  subnets                  = var.tier0_subnets
  tags                     = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

resource "azurerm_virtual_network_peering" "t0-to-hub" {
  provider   = azurerm.tier0
  depends_on = [azurerm_resource_group.tier0, module.spoke-network-t0, module.hub-network, module.firewall]

  name                         = "${var.tier0_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = azurerm_resource_group.tier0.name
  virtual_network_name         = module.spoke-network-t0.virtual_network_name
  remote_virtual_network_id    = module.hub-network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "hub-to-t0" {
  provider   = azurerm.hub
  depends_on = [azurerm_resource_group.hub, module.spoke-network-t0, module.hub-network, module.firewall]

  name                         = "${var.hub_vnetname}-to-${var.tier0_vnetname}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = module.hub-network.virtual_network_name
  remote_virtual_network_id    = module.spoke-network-t0.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

module "spoke-network-t1" {
  providers = {
    azurerm       = azurerm.tier1
    azurerm.tier1 = azurerm.tier1
  }
  depends_on = [azurerm_resource_group.tier1, module.hub-network, module.firewall]
  source     = "../modules/spoke"

  environment              = var.environment
  metadata_host            = var.metadata_host
  tier1_subid              = var.tier1_subid
  terraform_key_vault_name = var.terraform_key_vault_name
  terraform_key_vault_rg   = var.terraform_key_vault_rg
  param_secret_prefix      = lower(var.tier1_short_name)

  location = azurerm_resource_group.tier1.location

  firewall_private_ip = var.create_firewall ? module.firewall[0].firewall_private_ip : var.custom_firewall_ip

  laws_location                            = var.location
  laws_workspace_id                        = azurerm_log_analytics_workspace.laws.workspace_id
  laws_resource_id                         = azurerm_log_analytics_workspace.laws.id
  eventhub_name                            = var.eventhub_name_logs
  eventhub_namespace_authorization_rule_id = var.eventhub_namespace_authorization_rule_id
  flow_log_storage_id                      = var.flow_log_storage_id

  spoke_rgname             = azurerm_resource_group.tier1.name
  spoke_vnetname           = "${var.resourcePrefix}-${var.tier1_vnetname}-${var.resourceSuffix}"
  spoke_vnet_address_space = var.tier1_vnet_address_space
  subnets                  = var.tier1_subnets
  tags                     = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

resource "azurerm_virtual_network_peering" "t1-to-hub" {
  provider   = azurerm.tier1
  depends_on = [azurerm_resource_group.tier1, module.spoke-network-t1, module.hub-network, module.firewall]

  name                         = "${var.tier1_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = azurerm_resource_group.tier1.name
  virtual_network_name         = module.spoke-network-t1.virtual_network_name
  remote_virtual_network_id    = module.hub-network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "hub-to-t1" {
  provider   = azurerm.hub
  depends_on = [azurerm_resource_group.hub, module.spoke-network-t1, module.hub-network, module.firewall]

  name                         = "${var.hub_vnetname}-to-${var.tier1_vnetname}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = module.hub-network.virtual_network_name
  remote_virtual_network_id    = module.spoke-network-t1.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

module "spoke-network-t2" {
  providers = {
    azurerm       = azurerm.tier2
    azurerm.tier1 = azurerm.tier1
  }
  depends_on = [azurerm_resource_group.tier2, module.hub-network, module.firewall]
  source     = "../modules/spoke"

  environment              = var.environment
  metadata_host            = var.metadata_host
  tier1_subid              = var.tier1_subid
  terraform_key_vault_name = var.terraform_key_vault_name
  terraform_key_vault_rg   = var.terraform_key_vault_rg
  param_secret_prefix      = lower(var.tier2_short_name)

  location = azurerm_resource_group.tier2.location

  firewall_private_ip = var.create_firewall ? module.firewall[0].firewall_private_ip : var.custom_firewall_ip

  laws_location                            = var.location
  laws_workspace_id                        = azurerm_log_analytics_workspace.laws.workspace_id
  laws_resource_id                         = azurerm_log_analytics_workspace.laws.id
  eventhub_name                            = var.eventhub_name_logs
  eventhub_namespace_authorization_rule_id = var.eventhub_namespace_authorization_rule_id
  flow_log_storage_id                      = var.flow_log_storage_id

  spoke_rgname             = azurerm_resource_group.tier2.name
  spoke_vnetname           = "${var.resourcePrefix}-${var.tier2_vnetname}-${var.resourceSuffix}"
  spoke_vnet_address_space = var.tier2_vnet_address_space
  subnets                  = var.tier2_subnets
  tags                     = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

resource "azurerm_virtual_network_peering" "t2-to-hub" {
  provider   = azurerm.tier2
  depends_on = [azurerm_resource_group.tier2, module.spoke-network-t2, module.hub-network, module.firewall]

  name                         = "${var.tier2_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = azurerm_resource_group.tier2.name
  virtual_network_name         = module.spoke-network-t2.virtual_network_name
  remote_virtual_network_id    = module.hub-network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "hub-to-t2" {
  provider   = azurerm.hub
  depends_on = [azurerm_resource_group.hub, module.spoke-network-t2, module.hub-network, module.firewall]

  name                         = "${var.hub_vnetname}-to-${var.tier2_vnetname}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = module.hub-network.virtual_network_name
  remote_virtual_network_id    = module.spoke-network-t2.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# Private Link
module "private_link" {
  providers = { azurerm = azurerm.hub }
  source    = "../modules/private-link"

  name                       = azurerm_log_analytics_workspace.laws.name
  location                   = var.location
  log_analytics_workspace_id = sensitive(azurerm_log_analytics_workspace.laws.id)
  resource_group_name        = azurerm_resource_group.hub.name
  vnet_id                    = module.hub-network.virtual_network_id
  # JC Note: this is specific for the default subnet layout
  subnet_id = module.hub-subnets["hubSubnet"].subnet_id

  tags = var.tags
}

################################
### STAGE 3: Remote Access   ###
################################

#########################################################################
### This stage is optional based on the value of `create_bastion_jumpbox`
#########################################################################

module "jumpbox-subnet" {
  count = var.create_bastion_jumpbox ? 1 : 0

  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network, module.firewall, azurerm_log_analytics_workspace.laws]
  source     = "../modules/subnet"

  name                 = var.jumpbox_subnet.name
  location             = var.location
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = "${var.resourcePrefix}-${var.hub_vnetname}-${var.resourceSuffix}"
  address_prefixes     = var.jumpbox_subnet.address_prefixes
  service_endpoints    = lookup(var.jumpbox_subnet, "service_endpoints", [])

  private_endpoint_network_policies_enabled     = lookup(var.jumpbox_subnet, "private_endpoint_network_policies_enabled", null)
  private_link_service_network_policies_enabled = lookup(var.jumpbox_subnet, "private_link_service_network_policies_enabled", null)

  # JC Note: Don't use a jumpbox and modified subnet module
  # nsg_name  = var.jumpbox_subnet.nsg_name
  # nsg_rules = var.jumpbox_subnet.nsg_rules

  nsg_rules_names = []
  nsg_rules_map   = []

  # routetable_name     = var.jumpbox_subnet.routetable_name
  firewall_ip_address = var.create_firewall ? module.firewall[0].firewall_private_ip : var.custom_firewall_ip

  flow_log_storage_id = var.flow_log_storage_id
  # JC Note: Using centralized log storage
  # log_analytics_storage_id                 = module.hub-network.log_analytics_storage_id
  log_analytics_workspace_id               = azurerm_log_analytics_workspace.laws.workspace_id
  log_analytics_workspace_location         = var.location
  log_analytics_workspace_resource_id      = azurerm_log_analytics_workspace.laws.id
  eventhub_name                            = var.eventhub_name_logs
  eventhub_namespace_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  tags = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

module "bastion-host" {
  count = var.create_bastion_jumpbox ? 1 : 0

  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network, module.firewall, module.jumpbox-subnet]
  source     = "../modules/bastion"

  resource_group_name   = azurerm_resource_group.hub.name
  location              = azurerm_resource_group.hub.location
  virtual_network_name  = "${var.resourcePrefix}-${var.hub_vnetname}-${var.resourceSuffix}"
  bastion_host_name     = var.bastion_host_name
  subnet_address_prefix = var.bastion_address_space
  public_ip_name        = var.bastion_public_ip_name
  ipconfig_name         = var.bastion_ipconfig_name
  tags                  = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

module "jumpbox" {
  count = var.create_bastion_jumpbox ? 1 : 0

  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network, module.firewall, module.jumpbox-subnet]
  source     = "../modules/jumpbox"

  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = "${var.resourcePrefix}-${var.hub_vnetname}-${var.resourceSuffix}"
  subnet_name          = var.jumpbox_subnet.name
  location             = var.location

  keyvault_name = var.jumpbox_keyvault_name

  tenant_id = data.azurerm_client_config.current_client.tenant_id
  object_id = data.azurerm_client_config.current_client.object_id

  windows_name          = var.jumpbox_windows_vm_name
  windows_size          = var.jumpbox_windows_vm_size
  windows_publisher     = var.jumpbox_windows_vm_publisher
  windows_offer         = var.jumpbox_windows_vm_offer
  windows_sku           = var.jumpbox_windows_vm_sku
  windows_image_version = var.jumpbox_windows_vm_version

  linux_name          = var.jumpbox_linux_vm_name
  linux_size          = var.jumpbox_linux_vm_size
  linux_publisher     = var.jumpbox_linux_vm_publisher
  linux_offer         = var.jumpbox_linux_vm_offer
  linux_sku           = var.jumpbox_linux_vm_sku
  linux_image_version = var.jumpbox_linux_vm_version
  tags                = merge(var.tags, { "resourcePrefix" = "${var.resourcePrefix}" })
}

#####################################
### STAGE 4: Compliance example   ###
#####################################

module "hub-policy-assignment" {
  count = var.create_policy_assignment ? 1 : 0

  providers                           = { azurerm = azurerm.hub }
  source                              = "../modules/policy-assignments"
  depends_on                          = [azurerm_resource_group.hub, azurerm_log_analytics_workspace.laws]
  resource_group_name                 = azurerm_resource_group.hub.name
  laws_instance_id                    = azurerm_log_analytics_workspace.laws.workspace_id
  environment                         = var.environment # Example "usgovernment"
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id
}

module "tier0-policy-assignment" {
  count = var.create_policy_assignment ? 1 : 0

  providers                           = { azurerm = azurerm.tier0 }
  source                              = "../modules/policy-assignments"
  depends_on                          = [azurerm_resource_group.tier0, azurerm_log_analytics_workspace.laws]
  resource_group_name                 = azurerm_resource_group.tier0.name
  laws_instance_id                    = azurerm_log_analytics_workspace.laws.workspace_id
  environment                         = var.environment # Example "usgovernment"
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id
}

module "tier1-policy-assignment" {
  count = var.create_policy_assignment ? 1 : 0

  providers                           = { azurerm = azurerm.tier1 }
  source                              = "../modules/policy-assignments"
  depends_on                          = [azurerm_resource_group.tier1, azurerm_log_analytics_workspace.laws]
  resource_group_name                 = azurerm_resource_group.tier1.name
  laws_instance_id                    = azurerm_log_analytics_workspace.laws.workspace_id
  environment                         = var.environment # Example "usgovernment"
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id
}

module "tier2-policy-assignment" {
  count = var.create_policy_assignment ? 1 : 0

  providers                           = { azurerm = azurerm.tier2 }
  source                              = "../modules/policy-assignments"
  depends_on                          = [azurerm_resource_group.tier2, azurerm_log_analytics_workspace.laws]
  resource_group_name                 = azurerm_resource_group.tier2.name
  laws_instance_id                    = azurerm_log_analytics_workspace.laws.workspace_id
  environment                         = var.environment # Example "usgovernment"
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id
}
