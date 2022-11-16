variable "sub_id" {
  description = "ID of the Subscription"
  type        = string
  default     = null
  sensitive   = true
}

variable "sub_owners" {
  description = "List of Subscription Owner Principal IDs."
  type        = list(string)
  default     = []
}

variable "security_contact_email" {
  description = "Email address to send security notifications to."
  type        = string
}

variable "defender_tier" {
  description = "Whether Defender Standard or Free tier should be used."
  type        = string
  default     = "Standard"
}
