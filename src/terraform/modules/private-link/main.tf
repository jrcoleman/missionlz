# Create Private Link Scope for Log Analytics

resource "random_id" "plscope" {
  keepers = {
    name = var.name
  }
  byte_length = 4
}

resource "azurerm_monitor_private_link_scope" "global" {
  name = "plscope${random_id.plscope.keepers.name}${random_id.plscope.hex}"
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_monitor_private_link_scoped_service" "laws" {
  name = "plscres${random_id.plscope.keepers.name}${random_id.plscope.hex}"
  resource_group_name = var.resource_group_name
  scope_name = azurerm_monitor_private_link_scope.global.name
  linked_resource_id = var.log_analytics_workspace_id
}

resource "azurerm_private_endpoint" "laws" {
  name = "pl${random_id.plscope.keepers.name}${random_id.plscope.hex}"
  location = var.location
  resource_group_name = var.resource_group_name
  subnet_id = var.subnet_id

  private_service_connection {
    name = "plconn${random_id.plscope.keepers.name}${random_id.plscope.hex}"
    is_manual_connection = false
    private_connection_resource_id = azurerm_monitor_private_link_scope.global.id
    subresource_names = [
      "azuremonitor",
    ]
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor.id,
      azurerm_private_dns_zone.oms_opinsights.id,
      azurerm_private_dns_zone.ods_opinsights.id,
      azurerm_private_dns_zone.agentsvc.id,
      azurerm_private_dns_zone.blob.id
    ]
  }

  depends_on = [
    azurerm_monitor_private_link_scoped_service.laws,
  ]

  tags = var.tags
}

resource "azurerm_private_dns_zone" "monitor" {
  name = "privatelink.monitor.azure.com"
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitor" {
  name = "${azurerm_private_dns_zone.monitor.name}-link"
  resource_group_name = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor.name
  virtual_network_id = var.vnet_id
  depends_on = [
    azurerm_private_dns_zone.monitor
  ]
}

resource "azurerm_private_dns_zone" "oms_opinsights" {
  name = "privatelink.oms.opinsights.azure.com"
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms_opinsights" {
  name = "${azurerm_private_dns_zone.oms_opinsights.name}-link"
  resource_group_name = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.oms_opinsights.name
  virtual_network_id = var.vnet_id
  depends_on = [
    azurerm_private_dns_zone.oms_opinsights,
    azurerm_private_dns_zone_virtual_network_link.monitor
  ]
}

resource "azurerm_private_dns_zone" "ods_opinsights" {
  name = "privatelink.ods.opinsights.azure.com"
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods_opinsights" {
  name = "${azurerm_private_dns_zone.ods_opinsights.name}-link"
  resource_group_name = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ods_opinsights.name
  virtual_network_id = var.vnet_id
  depends_on = [
    azurerm_private_dns_zone.ods_opinsights,
    azurerm_private_dns_zone_virtual_network_link.oms_opinsights
  ]
}

resource "azurerm_private_dns_zone" "agentsvc" {
  name = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc" {
  name = "${azurerm_private_dns_zone.agentsvc.name}-link"
  resource_group_name = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.agentsvc.name
  virtual_network_id = var.vnet_id
  depends_on = [
    azurerm_private_dns_zone.agentsvc,
    azurerm_private_dns_zone_virtual_network_link.ods_opinsights
  ]
}

resource "azurerm_private_dns_zone" "blob" {
  name = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name = "${azurerm_private_dns_zone.blob.name}-link"
  resource_group_name = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id = var.vnet_id
  depends_on = [
    azurerm_private_dns_zone.blob,
    azurerm_private_dns_zone_virtual_network_link.agentsvc
  ]
}
