# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "hub_subid" {
  description = "Subscription ID where the Hub Resource Group is provisioned"
  value       = var.hub_subid
  sensitive   = true
}

output "hub_rgname" {
  description = "The Hub Resource Group name"
  value       = azurerm_resource_group.hub.name
}

output "hub_vnetname" {
  description = "The Hub Virtual Network name"
  value       = module.hub-network.virtual_network_name
}

output "firewall_private_ip" {
  description = "Firewall private IP"
  value       = var.create_firewall ? module.firewall[0].firewall_private_ip : var.custom_firewall_ip
  sensitive   = true
}

output "tier1_subid" {
  description = "Subscription ID where the Tier 1 Resource Group is provisioned"
  value       = coalesce(var.tier1_subid, var.hub_subid)
  sensitive   = true
}

output "laws_name" {
  description = "LAWS Name"
  value       = azurerm_log_analytics_workspace.laws.name
}

output "laws_rgname" {
  description = "Resource Group for Laws"
  value       = azurerm_log_analytics_workspace.laws.resource_group_name
}

output "laws_instance_id" {
  description = "ID of the Log Analytics Workspace instance"
  value       = azurerm_log_analytics_workspace.laws.workspace_id
  sensitive   = true
}

output "laws_resource_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.laws.id
  sensitive   = true
}

output "identity_rgname" {
  description = "Resource Group for the Identity Subscription"
  value       = azurerm_resource_group.tier0.name
}
