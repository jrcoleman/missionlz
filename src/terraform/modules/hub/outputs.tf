# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
output "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  value       = module.hub-network.resource_group_name
}

output "resource_group_location" {
  description = "The location of the resource group in which resources are created"
  value       = module.hub-network.resource_group_location
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = module.hub-network.virtual_network_name
}

output "virtual_network_address_space" {
  description = "List of address spaces that are used the virtual network."
  value       = module.hub-network.virtual_network_address_space
  sensitive   = true
}

output "virtual_network_id" {
  description = "The id of the virtual network"
  value       = module.hub-network.virtual_network_id
  sensitive   = true
}

output "firewall_client_subnet_name" {
  description = "Firewall client subnet name."
  value       = var.create_firewall ? azurerm_subnet.fw_client[0].name : null
}

output "firewall_management_subnet_name" {
  description = "Firewall management subnet name."
  value       = var.create_firewall ? azurerm_subnet.fw_mgmt[0].name : null
}

output "firewall_client_subnet_id" {
  description = "Firewall client subnet ID."
  value       = var.create_firewall ? azurerm_subnet.fw_client[0].id : null
  sensitive   = true
}

output "firewall_mgmt_subnet_id" {
  description = "Firewall management subnet ID."
  value       = var.create_firewall ? azurerm_subnet.fw_mgmt[0].id : null
  sensitive   = true
}

# Using Centralized Log Storage
# output "log_analytics_storage_id" {
#   description = "Log Analytics Storage ID."
#   value       = var.create_log_storage ? module.hub-network.log_analytics_storage_id : null
#   sensitive = true
# }
