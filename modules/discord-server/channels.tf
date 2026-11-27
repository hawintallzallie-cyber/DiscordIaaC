# ---------------------------------------------------------------------------
# Categories and channels
#
# These are written as explicit, individually named resources rather than a
# for_each over a map of channel definitions. That is a deliberate choice:
# the interesting part of a Discord server is how channels and roles are wired
# together, and a generic channel factory hides exactly that wiring behind a
# layer of indirection. See docs/adr/0005.
#
# Permission overwrites live in permissions.tf, not in each channel's
# initial_permission_overwrites argument, because that argument only applies at
# creation time and would silently stop reflecting the repository afterwards.
# ---------------------------------------------------------------------------

resource "discord_category_channel" "information" {
  server_id        = var.server_id
  name             = "Information"
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "welcome" {
  server_id        = var.server_id
  category_id      = discord_category_channel.information.id
  name             = "welcome"
  topic            = "Start here. React in the Server Guide to pick your roles."
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "rules" {
  server_id        = var.server_id
  category_id      = discord_category_channel.information.id
  name             = "rules"
  topic            = "Be kind, keep it legal, listen to the moderators."
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "announcements" {
  server_id        = var.server_id
  category_id      = discord_category_channel.information.id
  name             = "announcements"
  topic            = "Server news. Ping @Announcements for anything important."
  audit_log_reason = local.audit_reason
}

resource "discord_category_channel" "community" {
  server_id        = var.server_id
  name             = "Community"
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "general" {
  server_id        = var.server_id
  category_id      = discord_category_channel.community.id
  name             = "general"
  topic            = "Talk about anything."
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "introductions" {
  server_id        = var.server_id
  category_id      = discord_category_channel.community.id
  name             = "introductions"
  topic            = "New here? Say hello."
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "media" {
  server_id        = var.server_id
  category_id      = discord_category_channel.community.id
  name             = "media"
  topic            = "Images, clips, memes and music links."
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "bot_commands" {
  server_id   = var.server_id
  category_id = discord_category_channel.community.id
  name        = "bot-commands"
  topic       = "Slash command spam goes here so it stays out of #general."

  # Slow mode, because this is where command spam lands.
  rate_limit_per_user = 3

  audit_log_reason = local.audit_reason
}

resource "discord_category_channel" "gaming" {
  server_id        = var.server_id
  name             = "Gaming"
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "gaming" {
  server_id        = var.server_id
  category_id      = discord_category_channel.gaming.id
  name             = "gaming"
  topic            = "What are we playing?"
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "looking_for_group" {
  server_id        = var.server_id
  category_id      = discord_category_channel.gaming.id
  name             = "looking-for-group"
  topic            = "Post here to find people to play with. Ping @Gaming."
  audit_log_reason = local.audit_reason
}

resource "discord_category_channel" "voice" {
  server_id        = var.server_id
  name             = "Voice"
  audit_log_reason = local.audit_reason
}

resource "discord_voice_channel" "lounge" {
  server_id          = var.server_id
  category_id        = discord_category_channel.voice.id
  name               = "Lounge"
  user_limit         = 10
  video_quality_mode = "auto"
  audit_log_reason   = local.audit_reason
}

resource "discord_voice_channel" "game_room" {
  server_id          = var.server_id
  category_id        = discord_category_channel.voice.id
  name               = "Game Room"
  user_limit         = 8
  video_quality_mode = "full"
  audit_log_reason   = local.audit_reason
}

resource "discord_voice_channel" "afk" {
  server_id        = var.server_id
  category_id      = discord_category_channel.voice.id
  name             = "AFK"
  audit_log_reason = local.audit_reason
}

# ---------------------------------------------------------------------------
# Staff area. Hidden from @everyone in permissions.tf.
# ---------------------------------------------------------------------------

resource "discord_category_channel" "staff" {
  server_id        = var.server_id
  name             = "Staff"
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "staff_chat" {
  server_id        = var.server_id
  category_id      = discord_category_channel.staff.id
  name             = "staff-chat"
  topic            = "Moderator coordination."
  audit_log_reason = local.audit_reason
}

resource "discord_text_channel" "mod_log" {
  server_id        = var.server_id
  category_id      = discord_category_channel.staff.id
  name             = "mod-log"
  topic            = "AutoMod alerts land here. Also Discord's community updates."
  audit_log_reason = local.audit_reason
}
