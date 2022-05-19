output "tier3_rg_name" {
  value = azurerm_resource_group.tier3.name
}

output "tier3_rg_id" {
  value = azurerm_resource_group.tier3.id
  sensitive = true
}
