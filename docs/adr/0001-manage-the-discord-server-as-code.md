# ADR 0001: Manage the Discord server as code

- **Status:** Accepted
- **Date:** 2026-11-27

## Context

The server needs roles, categories, channels, per-channel permissions and
moderation. Doing this by hand in Discord's UI has three problems:

1. It takes hours, and the permission matrix is the slowest part, because every
   channel has to be checked against every role individually.
2. Nothing records why a setting is the way it is. Six months later nobody
   remembers whether a channel is read-only on purpose.
3. There is no undo. A mis-click on a permission is silent and invisible until
   someone notices they cannot see a channel.

A second, honest motivation: this repository is a portfolio piece. A real
workflow — branches, reviewed pull requests, a staging environment, a gated
promotion to production — is worth more as a work sample than a working server
on its own.

## Decision

Define the server declaratively in Terraform. Every role, channel, permission
overwrite and AutoMod rule is a resource in this repository, applied by CI.

Changes to the server are made by opening a pull request, not by clicking in
Discord.

## Consequences

- The permission matrix becomes reviewable. `permissions.tf` is about 90 lines
  that a person can read in two minutes; the equivalent UI state cannot
  really be read at all.
- Rebuilding the server elsewhere becomes a `terraform apply` rather than an
  afternoon.
- Every change gets an audit trail twice over: the Git history, and the
  `audit_log_reason` written into Discord's own audit log.
- The cost is drift. Anyone with Manage Channels can still change things in the
  UI, and Terraform will revert them on the next apply. This is mitigated by
  giving the Moderator role no management permissions (see `roles.tf`) and
  documented in `docs/runbooks/drift-and-recovery.md`.
- The other cost is latency. Renaming a channel now takes a pull request
  instead of ten seconds. For a server this size that is a real downside,
  accepted because the reviewability is worth more.

## Alternatives considered

- **Discord server templates.** Free and instant, but they capture only
  channels and roles, carry no bots or AutoMod, and cannot be diffed or
  re-applied to an existing server. A template is a snapshot, not a source of
  truth.
- **Doing it by hand and writing it down afterwards.** The documentation would
  drift from reality within a week, which is worse than no documentation.
