output "storage_id" {
  value     = azurerm_storage_account.secure.id
  sensitive = true
}
