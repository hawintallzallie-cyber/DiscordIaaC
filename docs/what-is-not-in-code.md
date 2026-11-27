# What is not in code

An honest boundary. Claiming a server is fully managed as code, when parts of
it are not, is how documentation stops being trustworthy.

## Cannot be automated at all

| Thing | Why | Where it is covered |
| --- | --- | --- |
| Creating the server | Discord does not let bots create guilds. `discord_server_settings` adopts an existing one. | bootstrap step 2 |
| Inviting the bot | OAuth consent is a browser click by a human. | bootstrap step 4 |
| Moving the bot's role to the top | A bot cannot position its own role above itself. | bootstrap step 5 |
| Enabling Community | Discord requires a human to accept its community guidelines checklist. Terraform can set `community = true` only after that. | bootstrap step 11 |
| Server boosts, Nitro, vanity URLs | Tied to payment and boost level. | not managed |

## Deliberately not managed

| Thing | Why |
| --- | --- |
| Members and their roles | `discord_member_roles` exists, but putting people in Git means a pull request to give someone a role. Moderators assign roles by hand; Terraform owns which roles *exist* and what they can do. |
| Messages | `discord_message` exists. Pinned rules text could live here. Not used, because a channel whose contents are owned by Terraform surprises everyone who tries to edit a typo. |
| Bans | Better handled live by moderators than through a pull request. |
| Emoji and stickers | Supported by the provider, and easy to add later. Nothing to manage yet. |
| Scheduled events | Created ad hoc; no value in declaring them. |

## Not covered by staging

Staging runs with `enable_community = false`, so two resources are only ever
exercised in production:

- `discord_onboarding`
- `discord_welcome_screen`

A change to either is tested by reading the production plan carefully, not by
applying it to staging first. ADR 0003 explains why re-qualifying a disposable
server for Community every time was judged not worth it.

## Third-party bots, if any get added

No third-party bot is a dependency of this configuration (ADR 0004). If one is
added anyway — a music bot is the likely candidate, since Discord has no native
equivalent — then:

- Its **presence** cannot be managed by Terraform (OAuth click).
- Its **configuration** cannot be managed by Terraform (no public write API).
- Its **permissions in this server** still can be, through its role.

A music bot is a safe exception because it holds no server configuration. A
moderation or reaction-role bot is not, because its dashboard would quietly
become the real source of truth for how the server behaves.

## The two things that would break this project

1. **The provider is abandoned.** It is pre-1.0, seven weeks old, and
   organization-owned by one person. ADR 0002 names `petterl/discord` as the
   fallback and explains the migration cost.
2. **Someone with Admin restructures the server by hand.** Terraform reverts it
   on the next apply, which is correct behaviour and looks like vandalism to
   whoever did it. Covered in `runbooks/drift-and-recovery.md`.
