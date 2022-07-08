variable "terraform_key_vault_name" {
  description = "Name of the Params Key Vault"
  type        = string
  sensitive   = true
}

variable "terraform_key_vault_rg" {
  description = "RG Name of the Params Key Vault"
  type        = string
}

variable "param_secret_prefix" {
  description = "Prefix for secrets in the Params Key Vault"
  type        = string
  sensitive   = true
}

variable "name" {
  description = "The name of the subnet"
  type        = string
}

variable "default_nsg_rules" {
  description = "List of default nsg rules to include from the Params Key Vault"
  type        = list(string)
  default     = ["DenyHighRisk", "AllowNIHNetIn", "AllowNIHNetOut"]
}

variable "nsg_rules" {
  description = "List of nsg rule names to retrieve from the param key vault."
  type        = list(string)
  default     = []
}
