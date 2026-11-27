variable "server_id" {
  description = <<-DESC
    Discord guild (server) ID this configuration adopts. Discord does not let
    bots create servers, so the guild must already exist and the bot must
    already be a member with the required permissions.
  DESC
  type        = string

  validation {
    condition     = can(regex("^[0-9]{17,20}$", var.server_id))
    error_message = "server_id must be a Discord snowflake (17-20 digits). Enable Developer Mode in Discord, right-click the server, Copy Server ID."
  }
}

variable "server_name" {
  description = "Display name for the server."
  type        = string

  validation {
    condition     = length(var.server_name) >= 2 && length(var.server_name) <= 100
    error_message = "server_name must be 2-100 characters."
  }
}

variable "environment" {
  description = <<-DESC
    Short environment name ("staging" or "production"). Written into every
    resource's audit_log_reason so a human reading Discord's audit log can tell
    which pipeline made a change, rather than just seeing the bot's name.
  DESC
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be either \"staging\" or \"production\"."
  }
}

variable "enable_community" {
  description = <<-DESC
    Turn on Discord's Community feature. This is a prerequisite for the welcome
    screen and for onboarding, and Discord requires a rules channel and a
    public updates channel before it will accept the change.

    Kept off in staging so the environment stays cheap to tear down and rebuild.
  DESC
  type        = bool
  default     = false
}

variable "enable_onboarding" {
  description = <<-DESC
    Manage Guild Onboarding (the "Server Guide" / channels-and-roles picker
    that replaces reaction-role bots).

    Requires enable_community = true. Discord additionally enforces a minimum
    of 7 default channels, at least 5 of which @everyone can send messages in;
    default_channel_ids below satisfies that, but if you remove channels you
    must keep the count above the floor or the apply will fail.
  DESC
  type        = bool
  default     = false
}

variable "scam_keywords" {
  description = <<-DESC
    Keyword list for the AutoMod scam-and-giveaway rule. Matching is
    case-insensitive and a leading or trailing "*" acts as a wildcard.

    Slurs and sexual content are deliberately NOT listed here: Discord's
    maintained KEYWORD_PRESET wordsets cover those, so this repository never
    has to contain a list of slurs.
  DESC
  type        = list(string)
  default = [
    "free nitro",
    "nitro giveaway",
    "nitro gift",
    "discordgift",
    "discord-gift",
    "steam gift card",
    "free robux",
    "crypto giveaway",
    "airdrop claim",
    "claim your reward",
  ]

  validation {
    condition     = length(var.scam_keywords) <= 1000
    error_message = "Discord allows at most 1000 keywords per AutoMod rule."
  }

  validation {
    condition     = alltrue([for k in var.scam_keywords : length(k) <= 60])
    error_message = "Each AutoMod keyword must be 60 characters or fewer."
  }
}

variable "mention_spam_limit" {
  description = "Maximum unique mentions allowed in one message before AutoMod blocks it."
  type        = number
  default     = 5

  validation {
    condition     = var.mention_spam_limit >= 1 && var.mention_spam_limit <= 50
    error_message = "mention_spam_limit must be between 1 and 50 (Discord's ceiling)."
  }
}

variable "automod_timeout_seconds" {
  description = "How long AutoMod times a member out for on a scam or mention-spam hit."
  type        = number
  default     = 3600

  validation {
    condition     = var.automod_timeout_seconds >= 60 && var.automod_timeout_seconds <= 2419200
    error_message = "automod_timeout_seconds must be between 60 and 2419200 (4 weeks, Discord's maximum)."
  }
}
