# Create an encrypted and secured storage account using a cmk

# Providers

provider "azurerm" {
  alias           = "tier0"
  environment     = var.environment
  metadata_host   = var.metadata_host
  subscription_id = var.tier0_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# CMK Resources

data "azurerm_key_vault" "cmk" {
  provider            = azurerm.tier0
  name                = var.key_vault_name
  resource_group_name = var.key_vault_rg
}

resource "azurerm_key_vault_key" "cmk" {
  provider     = azurerm.tier0
  name         = "${var.name}-cmk"
  key_vault_id = sensitive(data.azurerm_key_vault.cmk.id)
  key_type     = var.key_type
  key_size     = var.key_size
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  tags         = var.tags
}

# JC Note: This is required to set the Rotation Policy This will be swapped for a proper resource when available.
resource "null_resource" "cmk-rotation-policy" {
  triggers = {
    ckm_id = azurerm_key_vault_key.cmk.id
  }
  provisioner "local-exec" {
    command = <<EOT
az keyvault key rotation-policy update --vault-name ${var.key_vault_name} --name ${azurerm_key_vault_key.cmk.name} --value ./modules/secure-storage-account/rotation-policy.json
    EOT
  }
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
  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }
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
  storage_account_id        = sensitive(azurerm_storage_account.secure.id)
  key_vault_id              = sensitive(data.azurerm_key_vault.cmk.id)
  key_name                  = azurerm_key_vault_key.cmk.name
  user_assigned_identity_id = var.identity_id
  lifecycle {
    ignore_changes = [
      key_vault_id
    ]
  }
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
