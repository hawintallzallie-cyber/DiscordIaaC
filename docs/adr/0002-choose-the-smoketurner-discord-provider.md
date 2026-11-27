# ADR 0002: Use the smoketurner/discord Terraform provider, pinned exactly

- **Status:** Accepted
- **Date:** 2026-11-27

## Context

There is no official Terraform provider for Discord. The community ecosystem
has fragmented, and picking the wrong one means a rewrite later.

What the survey found on 2026-11-27:

| Provider | State |
| --- | --- |
| `cryptiklemur/discord` (the original) | Last pushed 2023-07-28 |
| `Lucky3028/discord` | **Archived.** README says "Discontinued". Was by far the most used (~147k downloads); last release 2.7.0 on 2026-05-18 |
| `petterl/discord` | Live fork continuing the 2.x line; 2.10.0 on 2026-11-20. Single maintainer, 0 stars, GitHub issues disabled |
| `smoketurner/discord` | Ground-up rewrite on the Terraform Plugin Framework; 0.4.0 on 2026-11-02, pushed 2026-11-25. Organization-owned, MPL-2.0, issues open |

Picking by download count would have selected the archived one. Download counts
measure the past.

Coverage mattered as much as liveness. `petterl` has no emoji resource.
`smoketurner` exposes 42 resources including `auto_moderation_rule`,
`onboarding`, `welcome_screen` and `emoji` — which is what makes ADR 0004
possible at all. It also ships a documented migration guide away from the
archived provider, which is evidence the maintainer is thinking about other
people's state and not only their own.

## Decision

Use `smoketurner/discord`, pinned to an exact version (`0.4.0`) in each
environment's root module, with `~> 0.4.0` in the shared module, and
`.terraform.lock.hcl` committed.

Dependabot opens a weekly PR for new versions. CI runs a plan against staging
on that PR, so an upgrade is reviewed as a diff before it is merged.

## Consequences

- AutoMod, onboarding and the welcome screen are all manageable in Terraform,
  so the project needs neither a custom reconciler nor a third-party bot for
  them.
- The provider is pre-1.0 and about seven weeks old, with one GitHub star. A
  breaking change or an abandonment is a real possibility. Exact pinning means
  that risk shows up as a failed Dependabot PR rather than a surprise during an
  apply.
- If the provider is abandoned, the fallback is `petterl/discord`, which keeps
  the older schema. That migration would mean rewriting resource names and
  arguments; the module boundary in `modules/discord-server` is what keeps the
  blast radius to one directory.
- Because the version is pinned exactly in two root modules, a bump touches two
  files plus two lock files. Accepted: the alternative is a floating constraint
  that can break an apply with no code change.

## Alternatives considered

- **`petterl/discord`.** Minimal config churn from the archived provider, but
  no emoji support, issues disabled, no stated maintenance intent, and an
  unresolved lineage — its README names a different parent than the GitHub API
  reports. Kept as the documented fallback rather than the primary choice.
- **`Lucky3028/discord`.** The obvious choice by popularity, and wrong:
  archived and explicitly discontinued.
- **Writing our own reconciler in TypeScript against the Discord API.** Full
  control and no provider risk, at the cost of hand-rolling diffing,
  idempotency and state. That is a lot of undifferentiated work to rebuild what
  Terraform already does well. Reconsider only if the provider dies and no fork
  survives.
