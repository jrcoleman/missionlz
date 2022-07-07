# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  nsg_log_categories = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
}

resource "azurerm_subnet" "subnet" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = sensitive(var.address_prefixes)

  service_endpoints = var.service_endpoints

  enforce_private_link_endpoint_network_policies = var.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = var.enforce_private_link_service_network_policies
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  resource_group_name = azurerm_subnet.subnet.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_network_security_rule" "nsgrules" {
  for_each = var.nsg_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_ranges          = each.value.source_port_ranges
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefix       = sensitive(each.value.source_address_prefixes)
  destination_address_prefix  = sensitive(each.value.destination_address_prefixes)
  resource_group_name         = azurerm_network_security_group.nsg.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_route_table" "routetable" {
  count               = var.firewall_ip_address != "" ? 1 : 0
  name                = var.routetable_name
  resource_group_name = azurerm_subnet.subnet.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_route" "routetable" {
  count                  = var.firewall_ip_address != "" ? 1 : 0
  name                   = "default_route"
  resource_group_name    = azurerm_route_table.routetable[0].resource_group_name
  route_table_name       = azurerm_route_table.routetable[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_ip_address
}

resource "azurerm_subnet_route_table_association" "routetable" {
  count          = var.firewall_ip_address != "" ? 1 : 0
  subnet_id      = azurerm_subnet.subnet.id
  route_table_id = azurerm_route_table.routetable[0].id
}

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
