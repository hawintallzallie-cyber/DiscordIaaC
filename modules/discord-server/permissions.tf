# ---------------------------------------------------------------------------
# Permission overwrites
#
# Channels are written out one by one in channels.tf because their wiring is
# the interesting part. Overwrites are the opposite: the same rule applied to a
# set of channels. So these use for_each -- repetition is what for_each is for,
# and three near-identical blocks per rule would be the thing worth avoiding.
#
# In Discord, the @everyone role's ID is the guild's own ID. That is why
# var.server_id appears as an overwrite_id below.
#
# The Admin role is absent on purpose: ADMINISTRATOR bypasses channel
# overwrites entirely, so granting it access again would be dead configuration.
# ---------------------------------------------------------------------------

locals {
  # Readable by all, writable by staff.
  announce_only_channels = {
    welcome       = discord_text_channel.welcome.id
    rules         = discord_text_channel.rules.id
    announcements = discord_text_channel.announcements.id
  }

  # Invisible to all but staff. The category is included so that any channel
  # added to it later inherits the restriction by default.
  staff_only_channels = {
    category   = discord_category_channel.staff.id
    staff_chat = discord_text_channel.staff_chat.id
    mod_log    = discord_text_channel.mod_log.id
  }
}

resource "discord_channel_permission" "announce_only_everyone" {
  for_each = local.announce_only_channels

  channel_id   = each.value
  overwrite_id = var.server_id
  type         = "role"

  deny = provider::discord::permissions([
    "SEND_MESSAGES",
    "SEND_MESSAGES_IN_THREADS",
    "CREATE_PUBLIC_THREADS",
    "ADD_REACTIONS",
  ])

  audit_log_reason = local.audit_reason
}

resource "discord_channel_permission" "announce_only_moderator" {
  for_each = local.announce_only_channels

  channel_id   = each.value
  overwrite_id = discord_role.moderator.id
  type         = "role"

  # Re-grants what the @everyone deny above took away, for staff only.
  allow = provider::discord::permissions([
    "SEND_MESSAGES",
    "SEND_MESSAGES_IN_THREADS",
    "ADD_REACTIONS",
    "MANAGE_MESSAGES",
  ])

  audit_log_reason = local.audit_reason
}

resource "discord_channel_permission" "staff_hidden_from_everyone" {
  for_each = local.staff_only_channels

  channel_id   = each.value
  overwrite_id = var.server_id
  type         = "role"

  deny = provider::discord::permissions(["VIEW_CHANNEL"])

  audit_log_reason = local.audit_reason
}

resource "discord_channel_permission" "staff_visible_to_moderator" {
  for_each = local.staff_only_channels

  channel_id   = each.value
  overwrite_id = discord_role.moderator.id
  type         = "role"

  allow = provider::discord::permissions([
    "VIEW_CHANNEL",
    "SEND_MESSAGES",
    "READ_MESSAGE_HISTORY",
    "ATTACH_FILES",
    "EMBED_LINKS",
  ])

  audit_log_reason = local.audit_reason
}
