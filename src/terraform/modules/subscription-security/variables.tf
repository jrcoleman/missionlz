variable "security_contact_email" {
  description = "Email address to send security notifications to."
  type        = string
}

variable "defender_tier" {
  description = "Whether Defender Standard or Free tier should be used."
  type        = string
  default     = "Standard"
}
