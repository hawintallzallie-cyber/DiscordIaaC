locals {
  # Every managed resource carries this, so Discord's audit log explains itself.
  audit_reason = "Managed by Terraform (${var.environment})"

  # Channels every new member is dropped into. Discord's onboarding validation
  # requires at least 7 of these, with at least 5 that @everyone can post in.
  # The six conversational channels below satisfy the second condition.
  default_channel_ids = [
    discord_text_channel.welcome.id,
    discord_text_channel.rules.id,
    discord_text_channel.announcements.id,
    discord_text_channel.general.id,
    discord_text_channel.introductions.id,
    discord_text_channel.media.id,
    discord_text_channel.bot_commands.id,
    discord_text_channel.gaming.id,
    discord_text_channel.looking_for_group.id,
  ]
}

# Adopts the existing guild rather than creating it. Community is gated behind a
# variable because enabling it has prerequisites Discord validates server-side.
resource "discord_server_settings" "main" {
  server_id = var.server_id
  name      = var.server_name

  verification_level            = "medium"
  explicit_content_filter       = "all_members"
  default_message_notifications = "only_mentions"

  system_channel_id = discord_text_channel.general.id
  afk_channel_id    = discord_voice_channel.afk.id
  afk_timeout       = 300

  community                 = var.enable_community
  rules_channel_id          = var.enable_community ? discord_text_channel.rules.id : null
  public_updates_channel_id = var.enable_community ? discord_text_channel.mod_log.id : null

  premium_progress_bar_enabled = true

  audit_log_reason = local.audit_reason
}
