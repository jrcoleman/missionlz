# Create an encrypted and secured storage account using a cmk

# CMK Resources

resource "azurerm_key_vault_key" "cmk" {
  name         = "${var.name}-cmk"
  key_vault_id = var.key_vault_id
  key_type     = var.key_type
  key_size     = var.key_size
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  tags         = var.tags
}

# Storage Account Resources

resource "azurerm_storage_account" "secure" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_kind             = var.account_kind
  access_tier              = var.access_tier
  account_replication_type = var.replication
  # Security Arguments
  infrastructure_encryption_enabled = true
  enable_https_traffic_only         = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  blob_properties {
    versioning_enabled = true
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }
  tags = var.tags
}

# SA Security Resources

resource "azurerm_storage_account_network_rules" "secure" {
  storage_account_id         = sensitive(azurerm_storage_account.secure.id)
  default_action             = "Deny"
  bypass                     = ["AzureServices", "Logging", "Metrics"]
  ip_rules                   = var.ip_network_rules
  virtual_network_subnet_ids = var.subnet_id_network_rules
}

resource "azurerm_storage_account_customer_managed_key" "cmk" {
  storage_account_id = sensitive(azurerm_storage_account.secure.id)
  key_vault_id       = var.key_vault_id
  key_name           = azurerm_key_vault_key.cmk.name
}

# JC Note: In progress
# # Optional Private Endpoint Resources

# resource "azurerm_private_endpoint" "secure" {
#   count               = var.create_private_endpoint != null ? 1 : 0
#   name                = "${var.name}-private-endpoint"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   subnet_id           = var.endpoint_subnet_id

#   private_service_connection {
#     name                           = "${var.name}-private-service-connection"
#     private_connection_resource_id = sensitive(azurerm_storage_account.secure.id)
#     is_manual_connection           = false
#   }
#   tags = var.tags
# }
