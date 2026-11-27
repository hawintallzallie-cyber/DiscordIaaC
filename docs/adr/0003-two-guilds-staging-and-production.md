# ADR 0003: Run a throwaway staging guild alongside the real one

- **Status:** Accepted
- **Date:** 2026-11-27

## Context

Terraform's destructive operations are not reversible here. Deleting a Discord
channel deletes its message history, and no amount of state manipulation brings
it back. An apply that *replaces* a channel instead of updating it is therefore
a data-loss event, not an inconvenience.

Several arguments in this configuration force replacement when changed, and the
provider is new enough that its exact update-versus-replace behaviour is not
something to learn on a server people are using.

## Decision

Two Discord guilds, two HCP Terraform workspaces, one codebase:

- **staging** — a free, empty server nobody chats in. `enable_community` is off
  so it can be deleted and rebuilt at will.
- **production** — the real server.

A pull request plans against both. A merge to `main` applies to staging
automatically, then stops and waits for a human to approve the production job
through a GitHub Environment with a required reviewer.

Both environments call the same module. The only committed differences are the
guild ID, the server name, and the two Community flags.

## Consequences

- A replace-instead-of-update surprise happens in staging, where it costs
  nothing, and then shows up as a `destroy` line in the production plan comment
  before anyone approves it.
- The PR checklist can therefore ask a question that actually has an answer:
  does this plan destroy anything?
- Cost: every change is applied twice, and promotion adds a manual step. For a
  server with a handful of members that is deliberate overhead, kept because
  practising the promotion workflow is one of the project's stated goals.
- Cost: the two environments can drift apart if someone edits one tfvars file
  and not the other. Keeping the differences down to four values is what makes
  that easy to catch in review.

## Alternatives considered

- **One guild, apply straight to it.** Simpler, and every mistake lands on the
  server she is actually using. Rejected.
- **A staging guild mirroring production exactly, Community included.**
  Discord's Community feature has server-side prerequisites, so a rebuilt
  staging server has to re-qualify every time. Not worth it to test two
  resources. Those two are instead the only things staging does not cover, and
  that gap is written down in `docs/what-is-not-in-code.md`.
