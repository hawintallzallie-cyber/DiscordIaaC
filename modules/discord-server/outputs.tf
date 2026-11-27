output "server_id" {
  description = "The guild this configuration manages."
  value       = discord_server_settings.main.id
}

output "role_ids" {
  description = "Managed role IDs, keyed by their purpose. Useful for wiring up a bot later without hardcoding snowflakes."
  value = {
    admin         = discord_role.admin.id
    moderator     = discord_role.moderator.id
    gaming        = discord_role.gaming.id
    movie_night   = discord_role.movie_night.id
    music         = discord_role.music.id
    announcements = discord_role.announcements.id
  }
}

output "channel_ids" {
  description = "Managed channel IDs, keyed by name."
  value = {
    welcome           = discord_text_channel.welcome.id
    rules             = discord_text_channel.rules.id
    announcements     = discord_text_channel.announcements.id
    general           = discord_text_channel.general.id
    introductions     = discord_text_channel.introductions.id
    media             = discord_text_channel.media.id
    bot_commands      = discord_text_channel.bot_commands.id
    gaming            = discord_text_channel.gaming.id
    looking_for_group = discord_text_channel.looking_for_group.id
    staff_chat        = discord_text_channel.staff_chat.id
    mod_log           = discord_text_channel.mod_log.id
    lounge            = discord_voice_channel.lounge.id
    game_room         = discord_voice_channel.game_room.id
    afk               = discord_voice_channel.afk.id
  }
}

output "automod_rule_names" {
  description = "AutoMod rules under management, so a reviewer can see at a glance what moderation is in code."
  value = [
    discord_auto_moderation_rule.preset_wordsets.name,
    discord_auto_moderation_rule.spam.name,
    discord_auto_moderation_rule.scams.name,
    discord_auto_moderation_rule.mention_spam.name,
    discord_auto_moderation_rule.scam_profiles.name,
  ]
}

output "community_features_enabled" {
  description = "Whether Community, and therefore onboarding and the welcome screen, are managed in this environment."
  value = {
    community   = var.enable_community
    onboarding  = var.enable_onboarding
    welcome_bar = var.enable_community
  }
}
