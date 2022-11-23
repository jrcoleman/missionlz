# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      configuration_aliases = [azurerm.tier1]
    }
  }
}

# VNet

module "spoke-network" {
  source                              = "../virtual-network"
  location                            = var.location
  resource_group_name                 = var.spoke_rgname
  vnet_name                           = var.spoke_vnetname
  vnet_address_space                  = var.spoke_vnet_address_space
  log_analytics_workspace_resource_id = var.laws_resource_id

  tags = var.tags
}

# Subnets

module "subnet_params" {
  for_each = var.subnets

  source    = "../subnet-params"
  providers = { azurerm = azurerm.tier1 }

  terraform_key_vault_name = var.terraform_key_vault_name
  terraform_key_vault_rg   = var.terraform_key_vault_rg
  param_secret_prefix      = var.param_secret_prefix

  name              = each.value.name
  default_nsg_rules = each.value.default_nsg_rules
  nsg_rules         = each.value.nsg_rules
}

module "subnets" {
  depends_on = [module.spoke-network]
  source     = "../subnet"
  for_each   = var.subnets

  name                 = "${var.param_secret_prefix}-subnet-${each.value.name}"
  location             = var.location
  resource_group_name  = var.spoke_rgname
  virtual_network_name = var.spoke_vnetname
  address_prefixes     = module.subnet_params[each.key].address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  private_endpoint_network_policies_enabled     = lookup(each.value, "private_endpoint_network_policies_enabled", null)
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", null)

  nsg_rules_names = concat(each.value.default_nsg_rules, each.value.nsg_rules)
  nsg_rules_map   = module.subnet_params[each.key].nsg_rules

  firewall_ip_address = var.firewall_private_ip

  flow_log_storage_id                      = var.flow_log_storage_id
  log_analytics_workspace_id               = var.laws_workspace_id
  log_analytics_workspace_location         = var.laws_location
  log_analytics_workspace_resource_id      = var.laws_resource_id
  eventhub_name                            = var.eventhub_name
  eventhub_namespace_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  tags = var.tags
}
