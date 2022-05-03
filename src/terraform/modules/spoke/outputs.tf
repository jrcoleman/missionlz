# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "virtual_network_id" {
  description = "The id of the virtual network"
  value       = module.spoke-network.virtual_network_id
  sensitive = true
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value = module.spoke-network.virtual_network_name
}
