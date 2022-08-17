
output "cmk_identity_principal_id" {
  value     = azurerm_user_assigned_identity.cmk.principal_id
  sensitive = true
}

output "cmk_identity_id" {
  value     = azurerm_user_assigned_identity.cmk.id
  sensitive = true
}

output "cmk_key_vault_name" {
  value     = azurerm_key_vault.cmk.name
  sensitive = true
}

output "cmk_key_vault_id" {
  value     = azurerm_key_vault.cmk.id
  sensitive = true
}
