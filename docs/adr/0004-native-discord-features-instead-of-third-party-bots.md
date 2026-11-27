# ADR 0004: Use Discord's native features instead of third-party bots

- **Status:** Accepted
- **Date:** 2026-11-27

## Context

The original request was for "all the fancy bots" — meaning the usual stack of
MEE6, Dyno and Carl-bot for moderation, welcome messages and reaction roles.

That stack is the one part of a Discord server that genuinely resists
infrastructure-as-code:

- Inviting a bot is an OAuth consent click in a browser. It cannot be
  automated, and as a one-time bootstrap step that is fine.
- Configuring a bot happens in that bot's own web dashboard. There is no public
  write API for MEE6, Dyno or Carl-bot settings. That configuration cannot be
  version-controlled, reviewed or restored — and it quietly becomes the real
  source of truth for how the server behaves.

Meanwhile, most of what those bots get installed for is now native:

| Usually a bot | Native equivalent | In Terraform? |
| --- | --- | --- |
| Dyno / MEE6 automod | Discord AutoMod | Yes — `discord_auto_moderation_rule` |
| Carl-bot reaction roles | Guild Onboarding prompts | Yes — `discord_onboarding` |
| Welcome message bot | Welcome Screen + onboarding | Yes — `discord_welcome_screen` |
| Mute command | Native timeouts, including as an AutoMod action | Yes — as a rule action |

## Decision

Build the server out of Discord's own features first. No third-party bot is a
dependency of this configuration.

Specifically: AutoMod replaces the moderation bot, onboarding prompts replace
reaction roles, and the welcome screen replaces the welcome bot.

If something genuinely cannot be done natively and is still wanted, the answer
is to write a small bot of our own whose configuration is a file in this
repository — not to add one whose configuration lives in someone else's
dashboard.

## Consequences

- Moderation runs server-side at Discord. There is no bot to go offline, no
  dashboard to lose access to, and no free tier to outgrow.
- The entire behaviour of the server is reviewable in a diff. `automod.tf` *is*
  the moderation policy, and changing it requires a pull request.
- This repository contains no list of slurs. Discord maintains the `profanity`,
  `sexual_content` and `slurs` wordsets, and the configuration references them
  by name. Only the scam keyword list is ours, because no preset covers "free
  nitro" phishing.
- Cost: no levelling or XP. That is MEE6's actual differentiator and Discord has
  no native equivalent. If it is wanted, it is the first candidate for a custom
  bot.
- Cost: no music bot. Also no native equivalent, and this genuinely needs a
  third-party bot — which is fine, because a music bot holds no server
  configuration. Inviting one does not undermine this decision.
- Cost: onboarding and the welcome screen require Discord's Community feature,
  which drags in a verification level, an explicit content filter, a rules
  channel and a public updates channel. That coupling is why they sit behind
  `enable_community` rather than being on by default.

## Alternatives considered

- **Install the usual bots and write a runbook for their dashboards.** Fastest
  route to a working server. Rejected because it moves the most
  behaviour-defining configuration in the server outside version control, which
  defeats the project.
- **Write one bot that owns everything.** Maximum control, and a better story
  still, but weeks of work — and it would reimplement AutoMod worse than
  Discord does. Reserved for levelling, if that is ever actually wanted.
