
variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "key_vault_id" {
  description = "Id of the key vault for CMK encrpyption."
  type        = string
  sensitive   = true
}

variable "identity_id" {
  description = "Id of the identity for CMK encryption."
  type        = string
  sensitive   = true
}

# Optional Variables

variable "create_private_endpoint" {
  description = "Switch to create a private endpoint for the storage account."
  type        = string
  sensitive   = true
  default     = null
}


variable "endpoint_subnet_id" {
  description = "Id of subnet for the private endpoint."
  type        = string
  sensitive   = true
  default     = null
}

variable "ip_network_rules" {
  description = "List of IP ranges to add to network rules."
  type        = list(string)
  default     = null
}

variable "subnet_id_network_rules" {
  description = "List of subnet ids to add to network rules."
  type        = list(string)
  default     = null
}

variable "subresource_names" {
  description = "List of storage account subresources to connect to private endpoint."
  type        = list(string)
  default     = ["blob", "file", "queue", "table", "web"]
}

variable "key_type" {
  type    = string
  default = "RSA"
}

variable "key_size" {
  type    = number
  default = 4096
}

variable "key_expiry" {
  type    = string
  default = "P2Y"
}

variable "rotate_before_expiry" {
  type    = string
  default = "P30D"
}

variable "account_kind" {
  type    = string
  default = "StorageV2"
}

variable "account_tier" {
  type    = string
  default = "Standard"
}

variable "replication" {
  type    = string
  default = "ZRS"
}

variable "access_tier" {
  type    = string
  default = "Hot"
}

variable "tags" {
  default = {}
}
