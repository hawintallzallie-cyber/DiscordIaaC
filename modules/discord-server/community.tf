# ---------------------------------------------------------------------------
# Community-only features
#
# Both of these require Discord's Community feature, which is why they are
# gated on the same variables that enable it in main.tf. Terraform cannot
# express "apply this only after that server-side flag flips", so the flags are
# explicit and the two environments differ in exactly this one respect.
# ---------------------------------------------------------------------------

# The Server Guide. This is the replacement for a reaction-role bot: members
# pick interests on join, Discord grants the roles, and the whole mapping of
# option -> role lives in this file. See docs/adr/0004.
resource "discord_onboarding" "main" {
  count = var.enable_onboarding ? 1 : 0

  server_id = var.server_id
  enabled   = true
  mode      = "default"

  default_channel_ids = local.default_channel_ids

  prompts = [
    {
      title         = "What are you into?"
      type          = "multiple_choice"
      single_select = false
      required      = false
      in_onboarding = true

      options = [
        {
          title       = "Gaming"
          description = "Game chat and looking-for-group, plus the Gaming role."
          role_ids    = [discord_role.gaming.id]
          channel_ids = [
            discord_text_channel.gaming.id,
            discord_text_channel.looking_for_group.id,
          ]
        },
        {
          title       = "Movie nights"
          description = "Get pinged when a watch party is starting."
          role_ids    = [discord_role.movie_night.id]
        },
        {
          title       = "Music"
          description = "Share and talk about music."
          role_ids    = [discord_role.music.id]
          channel_ids = [discord_text_channel.media.id]
        },
      ]
    },
    {
      title         = "Server news"
      type          = "multiple_choice"
      single_select = true
      required      = false
      in_onboarding = true

      # No explicit "no thanks" option: the provider rejects an option that
      # grants neither a role nor a channel, and with required = false,
      # declining is simply not choosing.
      options = [
        {
          title       = "Ping me for announcements"
          description = "You will be mentioned for server news. Rare, we promise."
          role_ids    = [discord_role.announcements.id]
        },
      ]
    },
  ]

  audit_log_reason = local.audit_reason
}

# The panel shown to people who have not joined yet.
resource "discord_welcome_screen" "main" {
  count = var.enable_community ? 1 : 0

  server_id   = var.server_id
  enabled     = true
  description = "A small, friendly server. Read the rules, pick your roles, say hello."

  welcome_channels = [
    {
      channel_id  = discord_text_channel.rules.id
      description = "Read this first"
    },
    {
      channel_id  = discord_text_channel.introductions.id
      description = "Introduce yourself"
    },
    {
      channel_id  = discord_text_channel.general.id
      description = "Jump into the conversation"
    },
  ]

  audit_log_reason = local.audit_reason
}
