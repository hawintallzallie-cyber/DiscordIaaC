# Module: discord-server

The server, defined once and called by both environments.

This is not a general-purpose Discord module. It is one specific server
expressed as code — see
[ADR 0005](../../docs/adr/0005-explicit-resources-over-a-channel-factory.md)
for why that is deliberate rather than lazy.

## Usage

```hcl
module "server" {
  source = "../../modules/discord-server"

  server_id   = var.server_id
  server_name = var.server_name
  environment = "staging"

  enable_community  = false
  enable_onboarding = false
}
```

## Files

| File | Contains |
| --- | --- |
| `main.tf` | `local.audit_reason`, `local.default_channel_ids`, and `discord_server_settings` |
| `roles.tf` | Staff roles, interest roles, `@everyone`, and the role hierarchy |
| `channels.tf` | Categories, text channels, voice channels |
| `permissions.tf` | Channel permission overwrites, generated with `for_each` |
| `automod.tf` | The five AutoMod rules — this is the moderation policy |
| `community.tf` | Onboarding and welcome screen, both gated on Community |
| `variables.tf` | Inputs, with validation that fails at plan time rather than apply time |
| `outputs.tf` | Role and channel IDs, so a bot could be wired up later without hardcoded snowflakes |

## Inputs

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `server_id` | `string` | — | Guild snowflake. Validated as 17–20 digits. |
| `server_name` | `string` | — | 2–100 characters. |
| `environment` | `string` | — | `staging` or `production`. Written into every `audit_log_reason`. |
| `enable_community` | `bool` | `false` | Enables Discord Community. Prerequisite for the welcome screen. |
| `enable_onboarding` | `bool` | `false` | Manages the Server Guide. Requires `enable_community`. |
| `scam_keywords` | `list(string)` | 10 phrases | AutoMod keyword list. Deliberately contains no slurs. |
| `mention_spam_limit` | `number` | `5` | Unique mentions before AutoMod blocks a message. |
| `automod_timeout_seconds` | `number` | `3600` | Timeout length on a scam or mention-spam hit. |

## Design notes

**No `Member` role.** `@everyone` carries the baseline permissions. A `Member`
role would be an indirection that every new member has to be granted before the
server works at all, and gating a friends' server behind a role grant is cost
without benefit. Staff channels narrow access down from the baseline instead of
granting it up from zero.

**Role order lives in exactly one place.** Discord creates every new role at the
bottom of the list. `discord_role_positions` is the only resource that owns the
hierarchy, so there is one place to read it and one place to change it.

**The Moderator role cannot restructure the server.** It deliberately lacks
`MANAGE_CHANNELS`, `MANAGE_ROLES`, `MANAGE_GUILD` and `MANAGE_WEBHOOKS`.
Moderators moderate people; they do not change what Terraform owns. This keeps
the set of people who can cause drift down to the people who know this
repository exists.

**Permission overwrites, not `initial_permission_overwrites`.** Channels accept
overwrites inline at creation, but that argument applies only once and then
silently stops reflecting the repository. Standalone
`discord_channel_permission` resources keep being reconciled.

**`Admin` is absent from every overwrite.** `ADMINISTRATOR` bypasses channel
overwrites entirely, so granting it access again would be dead configuration.

**Permissions are strings, not numbers.** The provider expects a decimal
bitfield in a `String`, built with `provider::discord::permissions([...])`.
Colours work the same way: `provider::discord::color("#57F287")`. Both are
provider-defined functions, which require Terraform 1.8 or newer.

## Gotchas

- `local.default_channel_ids` must keep at least 7 entries, at least 5 of which
  `@everyone` can post in, or an onboarding apply fails Discord's validation.
- `enable_onboarding = true` with `enable_community = false` will fail. The
  variable descriptions say so; nothing enforces it, because the dependency is
  server-side.
- Adding a channel is three steps, not one: the resource, a line in
  `local.default_channel_ids` if members should land in it, and an entry in
  `outputs.channel_ids`.
