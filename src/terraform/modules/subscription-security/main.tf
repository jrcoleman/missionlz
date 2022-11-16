# Set Subscription RBAC
resource "azurerm_role_assignment" "sub_owner" {
  for_each             = toset(var.sub_owners)
  scope                = var.sub_id
  role_definition_name = "Owner"
  principal_id         = each.value
}

# Enable Security Email Alerts

resource "azurerm_security_center_contact" "security_contact" {
  email               = var.security_contact_email
  alert_notifications = true
  alerts_to_admins    = true
}

# Enable Audited Defender Solutions

resource "azurerm_security_center_subscription_pricing" "defender_sql" {
  tier          = var.defender_tier
  resource_type = "SqlServers"
}

resource "azurerm_security_center_subscription_pricing" "defender_containers" {
  tier          = var.defender_tier
  resource_type = "Containers"
}

resource "azurerm_security_center_subscription_pricing" "defender_arm" {
  tier          = var.defender_tier
  resource_type = "Arm"
}

resource "azurerm_security_center_subscription_pricing" "defender_kv" {
  tier          = var.defender_tier
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "defender_app_services" {
  tier          = var.defender_tier
  resource_type = "AppServices"
}

resource "azurerm_security_center_subscription_pricing" "defender_dns" {
  tier          = var.defender_tier
  resource_type = "Dns"
}

resource "azurerm_security_center_subscription_pricing" "defender_servers" {
  tier          = var.defender_tier
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "defender_storage" {
  tier          = var.defender_tier
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "defender_sql_vm" {
  tier          = var.defender_tier
  resource_type = "SqlServerVirtualMachines"
}

# Enable Log Analytics Agent Auto-provisioning

resource "azurerm_security_center_auto_provisioning" "laws_agent" {
  auto_provision = "On"
}
