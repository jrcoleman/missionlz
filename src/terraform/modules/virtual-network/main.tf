# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# JC Note: Switch to central Flow Log Storage Account
# resource "random_id" "storageaccount" {
#   byte_length = 12
# }

# resource "azurerm_storage_account" "loganalytics" {
#   name                      = format("%.24s", lower(replace("${azurerm_virtual_network.vnet.name}logs${random_id.storageaccount[0].id}", "/[[:^alnum:]]/", "")))
#   resource_group_name       = var.resource_group_name
#   location                  = var.location
#   account_kind              = "StorageV2"
#   account_tier              = "Standard"
#   account_replication_type  = "LRS"
#   enable_https_traffic_only = true
#   min_tls_version           = "TLS1_2"
#   tags                      = var.tags
# }
