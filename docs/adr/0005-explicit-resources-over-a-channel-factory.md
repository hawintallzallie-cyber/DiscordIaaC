# ADR 0005: Write channels out explicitly; use for_each only for real repetition

- **Status:** Accepted
- **Date:** 2026-11-27

## Context

The reflex when writing Terraform for fourteen similar channels is to define a
map of channel objects in a variable and loop over it with `for_each`. It is
shorter, and it feels more like engineering.

It is also the wrong shape here. The interesting content of a Discord server is
not the list of channels — it is how channels relate to roles: which role can
see the staff category, which channels are read-only, which channels an
onboarding option grants. A `for_each` over a channel map pushes all of that
into string keys and lookups, so the wiring that actually matters becomes the
hardest thing in the repository to read.

## Decision

Two rules:

1. **Resources whose wiring is the point are written out individually.**
   Categories, channels and roles each get a named resource. A reviewer can
   follow `discord_text_channel.mod_log` from its definition to the AutoMod
   rule that alerts into it by reading, not by resolving a key.
2. **`for_each` is used where the repetition is genuine.** The permission
   overwrites in `permissions.tf` apply the same two rules across two sets of
   channels — twelve near-identical resources with nothing to learn from their
   differences — so they are generated from a local map.

The dividing line: loop when the items differ only in identity; write it out
when they differ in meaning.

## Consequences

- `channels.tf` is long and almost entirely obvious, which is the intended
  trade. Adding a channel is a copy-paste plus one line in
  `local.default_channel_ids`.
- Renaming a Terraform resource (not a channel) still requires a `moved` block
  or a state move — the same as with `for_each` keys.
- The module is not reusable as a generic "Discord server" module. It is one
  specific server expressed as code. That is honest about what it is; a generic
  version would need exactly the abstraction this ADR rejects.
- Someone reviewing this repository as a work sample might read explicit
  resources as unsophisticated. This ADR exists so the choice reads as
  deliberate, which is the point of writing decisions down.

## Alternatives considered

- **A full channel factory** driven by a `map(object({...}))` variable with
  nested permission definitions. Flexible, compact, and it would make the
  staff-channel permission wiring genuinely hard to follow. Rejected.
- **A factory for channels but explicit permissions.** The worse half of both:
  channel resources become opaque addresses like
  `discord_text_channel.this["mod_log"]`, which then have to be referenced from
  the explicit permission blocks anyway.
