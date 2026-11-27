# ADR 0006: Keep state in HCP Terraform, with the organization out of the repo

- **Status:** Accepted
- **Date:** 2026-11-27

## Context

CI has to apply, so CI has to reach the state file. Local state on a laptop
cannot be shared with GitHub Actions, and committing state to Git is both a
locking problem and a secret-leak problem — Terraform state records resource
attributes in plaintext.

The state also needs locking. Two applies racing on the same guild is a
realistic failure mode once a merge to `main` and a manual run can both happen.

## Decision

Store state in HCP Terraform (free tier), one workspace per environment:
`discord-staging` and `discord-production`.

Each environment declares an empty `cloud {}` block. The organization comes
from `TF_CLOUD_ORGANIZATION` and the workspace from `TF_WORKSPACE`, both set as
environment variables in CI and in a local `.env`. Neither is committed.

The workspaces run in **local** execution mode: HCP stores state and holds the
lock, while plan and apply execute on the GitHub Actions runner. This keeps
`DISCORD_TOKEN` in GitHub Secrets instead of duplicating it as an HCP workspace
variable.

## Consequences

- State is shared, locked and versioned, and HCP keeps a history that can be
  rolled back to.
- The repository contains no account identifiers, so it can be made public as a
  portfolio piece without redaction.
- One token, `TF_API_TOKEN`, is the key to all state. It lives in GitHub
  Secrets and nowhere else.
- Cost: `terraform init` fails without those two environment variables set.
  That is a deliberate trade for not committing them, and
  `docs/runbooks/bootstrap.md` covers it as a numbered step.
- Cost: a dependency on a hosted service for a hobby server. If HCP's free tier
  changes, the migration is a new `backend` block plus
  `terraform init -migrate-state`.

## Alternatives considered

- **Local state, committed.** No locking, and state contains resource
  attributes that should not be in a public repository.
- **Local state, gitignored.** Works for one person on one laptop and makes CI
  impossible, which rules out the entire workflow this project exists to
  practise.
- **An S3-compatible bucket (AWS S3 or Cloudflare R2) with native locking.**
  Perfectly good, and slightly cheaper in dependencies, but it means managing a
  bucket, credentials and lifecycle rules to support one hobby project. HCP's
  free tier does the same job with one token.
- **Remote execution mode in HCP.** Would mean storing `DISCORD_TOKEN` as an
  HCP workspace variable, giving two places that hold the bot token. Local
  execution keeps it to one.
