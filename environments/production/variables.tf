variable "server_id" {
  description = "Discord guild ID for this environment."
  type        = string
}

variable "server_name" {
  description = "Display name for this environment's server."
  type        = string
}

variable "enable_community" {
  description = "Enable Discord's Community feature in this environment."
  type        = bool
  default     = false
}

variable "enable_onboarding" {
  description = "Manage Guild Onboarding in this environment. Requires enable_community."
  type        = bool
  default     = false
}
