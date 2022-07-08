# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  nsg_log_categories = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
}

# Params Key Vault

provider "azurerm" {
  alias           = "tier1"
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

data "azurerm_key_vault" "terraform_vault" {
  provider            = azurerm.tier1
  name                = var.terraform_key_vault_name
  resource_group_name = var.terraform_key_vault_rg
}

# NSG

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

data "azurerm_key_vault_secret" "default_nsg_rules" {
  for_each = to_set(var.default_nsg_rules)

  provider     = azurerm.tier1
  name         = "default-nsg-rule-${lower(each.key)}"
  key_vault_id = sensitive(data.azurerm_key_vault.terraform_vault.id)
}


resource "azurerm_network_security_rule" "default_nsgrules" {
  for_each = data.azurerm_key_vault_secret.default_nsg_rules

  name                         = jsondecode(each.value.value).name
  priority                     = jsondecode(each.value.value).priority
  direction                    = jsondecode(each.value.value).direction
  access                       = jsondecode(each.value.value).access
  protocol                     = jsondecode(each.value.value).protocol
  source_port_ranges           = jsondecode(each.value.value).source_port_ranges
  destination_port_ranges      = jsondecode(each.value.value).destination_port_ranges
  source_address_prefixes      = sensitive(jsondecode(each.value.value).source_address_prefixes)
  destination_address_prefixes = sensitive(jsondecode(each.value.value).destination_address_prefixes)
  resource_group_name          = azurerm_network_security_group.nsg.resource_group_name
  network_security_group_name  = azurerm_network_security_group.nsg.name
}

data "azurerm_key_vault_secret" "nsg_rules" {
  for_each = to_set(var.nsg_rules)

  provider     = azurerm.tier1
  name         = "${var.paramsecretprefix}-${lower(each.key)}"
  key_vault_id = sensitive(data.azurerm_key_vault.terraform_vault.id)
}


resource "azurerm_network_security_rule" "nsgrules" {
  for_each = data.azurerm_key_vault_secret.nsg_rules

  name                         = jsondecode(each.value.value).name
  priority                     = jsondecode(each.value.value).priority
  direction                    = jsondecode(each.value.value).direction
  access                       = jsondecode(each.value.value).access
  protocol                     = jsondecode(each.value.value).protocol
  source_port_ranges           = jsondecode(each.value.value).source_port_ranges
  destination_port_ranges      = jsondecode(each.value.value).destination_port_ranges
  source_address_prefixes      = sensitive(jsondecode(each.value.value).source_address_prefixes)
  destination_address_prefixes = sensitive(jsondecode(each.value.value).destination_address_prefixes)
  resource_group_name          = azurerm_network_security_group.nsg.resource_group_name
  network_security_group_name  = azurerm_network_security_group.nsg.name
}

# Subnet

data "azurerm_key_vault_secret" "address_prefixes" {
  provider     = azurerm.tier1
  name         = "${var.paramsecretprefix}-${lower(var.name)}"
  key_vault_id = sensitive(data.azurerm_key_vault.terraform_vault.id)
}

resource "azurerm_subnet" "subnet" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = sensitive(data.azurerm_key_vault_secret.address_prefixes)

  service_endpoints = var.service_endpoints

  enforce_private_link_endpoint_network_policies = var.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = var.enforce_private_link_service_network_policies
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = var.nsg_id
}


# Route Table 
# JC Note: Route Tables are managed by BGP advertisement for ExpressRoute.

# resource "azurerm_route" "routetable" {
#   count                  = var.firewall_ip_address != "" ? 1 : 0
#   name                   = "${var.name}-rt"
#   resource_group_name    = azurerm_route_table.routetable[0].resource_group_name
#   route_table_name       = azurerm_route_table.routetable[0].name
#   address_prefix         = "0.0.0.0/0"
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = var.firewall_ip_address
# }

# resource "azurerm_subnet_route_table_association" "routetable" {
#   count          = var.firewall_ip_address != "" ? 1 : 0
#   subnet_id      = azurerm_subnet.subnet.id
#   route_table_id = azurerm_route_table.routetable[0].id
# }

# Logging

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  depends_on = [azurerm_network_security_group.nsg]

  name               = "${azurerm_network_security_group.nsg.name}-nsg-diagnostics"
  target_resource_id = azurerm_network_security_group.nsg.id
  # JC Note: Switch to only centralized log storage
  # storage_account_id             = var.log_analytics_storage_id
  log_analytics_workspace_id     = var.log_analytics_workspace_resource_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  dynamic "log" {
    for_each = local.nsg_log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }
}

resource "azurerm_network_watcher_flow_log" "nsgfl" {
  depends_on = [azurerm_network_security_rule.nsgrules, azurerm_network_security_group.nsg]

  name                 = "${azurerm_network_security_group.nsg.name}-flow-log"
  network_watcher_name = "NetworkWatcher_${replace(var.location, " ", "")}"
  resource_group_name  = "NetworkWatcherRG"

  network_security_group_id = azurerm_network_security_group.nsg.id
  storage_account_id        = var.flow_log_storage_id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_in_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.log_analytics_workspace_id
    workspace_region      = var.log_analytics_workspace_location
    workspace_resource_id = var.log_analytics_workspace_resource_id
    interval_in_minutes   = 10
  }
}
