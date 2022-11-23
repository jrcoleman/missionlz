# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  nsg_log_categories = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
}

# NSG

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# JC Note: Key Vault parameters cause destruction setting ignore_changes to mitigate.
resource "azurerm_network_security_rule" "nsgrules" {
  for_each = toset(var.nsg_rules_names)

  name                         = var.nsg_rules_map[each.value].name
  priority                     = var.nsg_rules_map[each.value].priority
  direction                    = var.nsg_rules_map[each.value].direction
  access                       = var.nsg_rules_map[each.value].access
  protocol                     = var.nsg_rules_map[each.value].protocol
  source_port_range            = try(var.nsg_rules_map[each.value].source_port_range, null)
  source_port_ranges           = try(var.nsg_rules_map[each.value].source_port_ranges, null)
  destination_port_range       = try(var.nsg_rules_map[each.value].destination_port_range, null)
  destination_port_ranges      = try(var.nsg_rules_map[each.value].destination_port_ranges, null)
  source_address_prefix        = try(sensitive(var.nsg_rules_map[each.value].source_address_prefix), null)
  destination_address_prefix   = try(sensitive(var.nsg_rules_map[each.value].destination_address_prefix), null)
  source_address_prefixes      = try(sensitive(var.nsg_rules_map[each.value].source_address_prefixes), null)
  destination_address_prefixes = try(sensitive(var.nsg_rules_map[each.value].destination_address_prefixes), null)
  resource_group_name          = azurerm_network_security_group.nsg.resource_group_name
  network_security_group_name  = azurerm_network_security_group.nsg.name
  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

# Subnet

resource "azurerm_subnet" "subnet" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = sensitive(var.address_prefixes)

  service_endpoints = var.service_endpoints

  private_endpoint_network_policies_enabled     = var.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = var.private_link_service_network_policies_enabled
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
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

# JC Note: ignore_changes log set for diagnostic settings due to null bug
# JC Note: comment out ignore_changes to update diagnostic settings

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  depends_on = [azurerm_network_security_group.nsg]

  name                           = "${azurerm_network_security_group.nsg.name}-nsg-diagnostics"
  target_resource_id             = azurerm_network_security_group.nsg.id
  log_analytics_workspace_id     = var.log_analytics_workspace_resource_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_namespace_authorization_rule_id

  dynamic "log" {
    for_each = local.nsg_log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        days    = 180
        enabled = true
      }
    }
  }
  lifecycle {
    ignore_changes = [
      log
    ]
  }
}

resource "azurerm_network_watcher_flow_log" "nsgfl" {
  depends_on = [azurerm_network_security_rule.nsgrules, azurerm_network_security_group.nsg]

  name                 = "${azurerm_network_security_group.nsg.name}-flow-log"
  location             = var.location
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
  tags = var.tags
}
