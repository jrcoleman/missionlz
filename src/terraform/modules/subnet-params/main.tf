data "azurerm_key_vault" "terraform_vault" {
  name                = var.terraform_key_vault_name
  resource_group_name = var.terraform_key_vault_rg
}

data "azurerm_key_vault_secret" "address_prefixes" {
  name         = "${var.param_secret_prefix}-${lower(var.name)}"
  key_vault_id = sensitive(data.azurerm_key_vault.terraform_vault.id)
}

data "azurerm_key_vault_secret" "default_nsg_rules" {
  for_each = toset(var.default_nsg_rules)

  name         = "default-nsg-rule-${lower(each.key)}"
  key_vault_id = sensitive(data.azurerm_key_vault.terraform_vault.id)
}

data "azurerm_key_vault_secret" "nsg_rules" {
  for_each = toset(var.nsg_rules)

  name         = "${var.param_secret_prefix}-${lower(each.key)}"
  key_vault_id = sensitive(data.azurerm_key_vault.terraform_vault.id)
}
