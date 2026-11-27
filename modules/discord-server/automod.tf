# ---------------------------------------------------------------------------
# AutoMod
#
# This is the file that replaces a moderation bot. Discord's own AutoMod runs
# server-side with no uptime to worry about, no third-party dashboard, and --
# the point of this project -- a configuration that lives in Git.
#
# Discord allows at most: 6 keyword rules, 1 spam, 1 keyword_preset,
# 1 mention_spam and 1 member_profile rule per server. The five rules below sit
# inside those limits with room for five more keyword rules.
#
# A note on the TIMEOUT action: Discord only accepts it on keyword and
# mention_spam rules, which is why the spam and preset rules below alert
# instead of punishing.
# ---------------------------------------------------------------------------

locals {
  # Staff are exempt from AutoMod so they can quote and discuss what it caught.
  automod_exempt_role_ids = [
    discord_role.admin.id,
    discord_role.moderator.id,
  ]
}

# Discord's own maintained wordsets for profanity, sexual content and slurs.
# Using the presets is why this repository contains no list of slurs.
resource "discord_auto_moderation_rule" "preset_wordsets" {
  server_id    = var.server_id
  name         = "Blocked words (Discord presets)"
  enabled      = true
  event_type   = "message_send"
  trigger_type = "keyword_preset"

  trigger_metadata = {
    presets = ["profanity", "sexual_content", "slurs"]
  }

  actions = [
    {
      type           = "block_message"
      custom_message = "That word is blocked on this server."
    },
    {
      type       = "send_alert_message"
      channel_id = discord_text_channel.mod_log.id
    },
  ]

  exempt_role_ids = local.automod_exempt_role_ids

  audit_log_reason = local.audit_reason
}

# Discord's heuristic spam detection.
resource "discord_auto_moderation_rule" "spam" {
  server_id    = var.server_id
  name         = "Spam"
  enabled      = true
  event_type   = "message_send"
  trigger_type = "spam"

  actions = [
    { type = "block_message" },
    {
      type       = "send_alert_message"
      channel_id = discord_text_channel.mod_log.id
    },
  ]

  exempt_role_ids = local.automod_exempt_role_ids

  audit_log_reason = local.audit_reason
}

# The rule that actually matters for a small server: compromised accounts
# posting "free nitro" links. Blocks the message and times the account out so
# it cannot keep posting while nobody is awake to notice.
resource "discord_auto_moderation_rule" "scams" {
  server_id    = var.server_id
  name         = "Scams and fake giveaways"
  enabled      = true
  event_type   = "message_send"
  trigger_type = "keyword"

  trigger_metadata = {
    keyword_filter = var.scam_keywords
  }

  actions = [
    {
      type           = "block_message"
      custom_message = "That looked like a scam link, so it was blocked."
    },
    {
      type             = "timeout"
      duration_seconds = var.automod_timeout_seconds
    },
    {
      type       = "send_alert_message"
      channel_id = discord_text_channel.mod_log.id
    },
  ]

  exempt_role_ids = local.automod_exempt_role_ids

  audit_log_reason = local.audit_reason
}

# Mention raids.
resource "discord_auto_moderation_rule" "mention_spam" {
  server_id    = var.server_id
  name         = "Mention spam"
  enabled      = true
  event_type   = "message_send"
  trigger_type = "mention_spam"

  trigger_metadata = {
    mention_total_limit             = var.mention_spam_limit
    mention_raid_protection_enabled = true
  }

  actions = [
    { type = "block_message" },
    {
      type             = "timeout"
      duration_seconds = var.automod_timeout_seconds
    },
    {
      type       = "send_alert_message"
      channel_id = discord_text_channel.mod_log.id
    },
  ]

  # Moderators legitimately mention several roles at once.
  exempt_role_ids = local.automod_exempt_role_ids

  audit_log_reason = local.audit_reason
}

# Scam text hidden in nicknames and bios, which message rules never see.
# member_profile rules cannot use presets, only keyword lists.
resource "discord_auto_moderation_rule" "scam_profiles" {
  server_id    = var.server_id
  name         = "Scam text in member profiles"
  enabled      = true
  event_type   = "member_update"
  trigger_type = "member_profile"

  trigger_metadata = {
    keyword_filter = var.scam_keywords
  }

  # The only action Discord accepts for a profile rule: the member keeps the
  # profile but cannot interact until they change it.
  actions = [
    { type = "block_member_interaction" },
  ]

  exempt_role_ids = local.automod_exempt_role_ids

  audit_log_reason = local.audit_reason
}
