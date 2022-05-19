# Create CMK Key Vault and User assigned identityS

resource "azurerm_user_assigned_identity" "cmk" {
  name = var.identity_name
  resource_group_name = var.resource_group_name
  location = var.location
  tags = var.tags
}

# JC Note: Need to define network acls

resource "azurerm_key_vault" "cmk" {
  name = var.kv_name
  location = var.location
  resource_group_name = var.resource_group_name
  sku_name = "standard"
  enabled_for_disk_encryption = true
  enabled_for_template_deployment = true
  tenant_id = var.tenant_id
  purge_protection_enabled = true
  soft_delete_retention_days = 90
  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "cmk_identity" {
  key_vault_id = azurerm_key_vault.cmk.id
  tenant_id = var.tenant_id
  object_id = azurerm_user_assigned_identity.cmk.principal_id
  key_permissions = ["Get", "UnwrapKey", "WrapKey"]
}
