# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  value       = data.azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "The id of the resource group in which resources are created"
  value       = data.azurerm_resource_group.rg.id
  sensitive   = true
}

output "resource_group_location" {
  description = "The location of the resource group in which resources are created"
  value       = data.azurerm_resource_group.rg.location
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = element(concat(azurerm_virtual_network.vnet.*.name, [""]), 0)
}

output "virtual_network_id" {
  description = "The id of the virtual network"
  value       = element(concat(azurerm_virtual_network.vnet.*.id, [""]), 0)
  sensitive   = true
}

output "virtual_network_address_space" {
  description = "List of address spaces that are used the virtual network."
  value       = element(coalescelist(azurerm_virtual_network.vnet.*.address_space, [""]), 0)
  sensitive   = true
}

# JC Note: Switch to centralized flow log storage
# output "log_analytics_storage_id" {
#   description = "The id of the storage account that stores Log Analytics logs"
#   value       = var.create_log_storage ? azurerm_storage_account.loganalytics[0].id : null
#   sensitive = true
# }
