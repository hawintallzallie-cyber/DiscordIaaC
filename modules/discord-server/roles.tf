# ---------------------------------------------------------------------------
# Roles
#
# There is deliberately no "Member" role. @everyone carries the baseline
# permissions, so a Member role would be an extra indirection that every new
# member has to be granted before the server works. Staff roles narrow the
# server down; interest roles are opt-in labels with no permissions at all.
#
# Role ORDER is not set here. Discord creates every new role at the bottom of
# the list; discord_role_positions below is the single resource that owns the
# hierarchy, so there is one place to read it and one place to change it.
# ---------------------------------------------------------------------------

resource "discord_role" "admin" {
  server_id   = var.server_id
  name        = "Admin"
  color       = provider::discord::color("#E74C3C")
  hoist       = true
  mentionable = false
  permissions = provider::discord::permissions(["ADMINISTRATOR"])

  audit_log_reason = local.audit_reason
}

resource "discord_role" "moderator" {
  server_id   = var.server_id
  name        = "Moderator"
  color       = provider::discord::color("#3498DB")
  hoist       = true
  mentionable = true

  # Enough to moderate, and nothing more. Notably absent: MANAGE_GUILD,
  # MANAGE_ROLES, MANAGE_CHANNELS and MANAGE_WEBHOOKS. Those would let a
  # moderator change the server out from under Terraform, which is the one
  # thing this project exists to prevent.
  permissions = provider::discord::permissions([
    "VIEW_CHANNEL",
    "SEND_MESSAGES",
    "SEND_MESSAGES_IN_THREADS",
    "CREATE_PUBLIC_THREADS",
    "READ_MESSAGE_HISTORY",
    "ADD_REACTIONS",
    "ATTACH_FILES",
    "EMBED_LINKS",
    "MENTION_EVERYONE",
    "MANAGE_MESSAGES",
    "MANAGE_THREADS",
    "MANAGE_NICKNAMES",
    "KICK_MEMBERS",
    "BAN_MEMBERS",
    "MODERATE_MEMBERS",
    "VIEW_AUDIT_LOG",
    "CONNECT",
    "SPEAK",
    "MUTE_MEMBERS",
    "DEAFEN_MEMBERS",
    "MOVE_MEMBERS",
  ])

  audit_log_reason = local.audit_reason
}

# ---------------------------------------------------------------------------
# Interest roles
#
# These carry no permissions. They exist to be mentioned ("@Movie Night, we
# start in 10") and to be self-assigned through onboarding. This is what a
# reaction-role bot is normally installed for; see docs/adr/0004.
# ---------------------------------------------------------------------------

resource "discord_role" "gaming" {
  server_id        = var.server_id
  name             = "Gaming"
  color            = provider::discord::color("#9B59B6")
  mentionable      = true
  audit_log_reason = local.audit_reason
}

resource "discord_role" "movie_night" {
  server_id        = var.server_id
  name             = "Movie Night"
  color            = provider::discord::color("#E67E22")
  mentionable      = true
  audit_log_reason = local.audit_reason
}

resource "discord_role" "music" {
  server_id        = var.server_id
  name             = "Music"
  color            = provider::discord::color("#1ABC9C")
  mentionable      = true
  audit_log_reason = local.audit_reason
}

resource "discord_role" "announcements" {
  server_id        = var.server_id
  name             = "Announcements"
  color            = provider::discord::color("#F1C40F")
  mentionable      = true
  audit_log_reason = local.audit_reason
}

# ---------------------------------------------------------------------------
# @everyone
#
# The baseline every member gets. Staff channels are then hidden from this role
# by explicit overwrites in permissions.tf, rather than by starting from zero
# and granting access back channel by channel.
# ---------------------------------------------------------------------------

resource "discord_role_everyone" "everyone" {
  server_id = var.server_id

  permissions = provider::discord::permissions([
    "VIEW_CHANNEL",
    "SEND_MESSAGES",
    "SEND_MESSAGES_IN_THREADS",
    "CREATE_PUBLIC_THREADS",
    "READ_MESSAGE_HISTORY",
    "ADD_REACTIONS",
    "ATTACH_FILES",
    "EMBED_LINKS",
    "USE_EXTERNAL_EMOJIS",
    "USE_APPLICATION_COMMANDS",
    "CHANGE_NICKNAME",
    "CONNECT",
    "SPEAK",
    "STREAM",
    "USE_VAD",
    "CREATE_INSTANT_INVITE",
  ])

  audit_log_reason = local.audit_reason
}

# Owns the role hierarchy, highest first. Discord will not let the bot move a
# role above its own highest role, so the bot's integration role must sit at
# the top of the list -- see docs/runbooks/bootstrap.md step 5.
resource "discord_role_positions" "main" {
  server_id = var.server_id

  role_ids = [
    discord_role.admin.id,
    discord_role.moderator.id,
    discord_role.announcements.id,
    discord_role.gaming.id,
    discord_role.movie_night.id,
    discord_role.music.id,
  ]

  audit_log_reason = local.audit_reason
}
