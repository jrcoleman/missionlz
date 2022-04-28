output "subnet_id" {
  description = "The id of the subnets"
  value = azurerm_subnet.subnet.id
  sensitive = true
}