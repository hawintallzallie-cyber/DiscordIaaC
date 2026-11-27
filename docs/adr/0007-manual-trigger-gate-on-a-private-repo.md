# ADR 0007: Gate production with a manual trigger, not a GitHub Environment

- **Status:** Accepted
- **Date:** 2026-11-27
- **Amends:** [ADR 0003](0003-two-guilds-staging-and-production.md)

## Context

ADR 0003 put the production gate in a GitHub Environment with a required
reviewer, and argued that keeping it in GitHub rather than in YAML meant it
could not be removed by editing a workflow in the pull request it was guarding.

That reasoning was sound. The plan assumption behind it was not.

The repository is **private on GitHub Free**, and on that plan:

- Deployment protection rules — required reviewers, wait timers — are
  [available only on public repositories](https://docs.github.com/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment).
  The docs go further: on Free you cannot configure environments on a private
  repository at all.
- Branch protection and rulesets are likewise unavailable, so `main` cannot
  require a passing `plan` or an approving review before a merge.
- `CODEOWNERS` therefore has nothing enforcing it.

The failure mode mattered more than the missing feature. `environment:
production` does not error when protection rules are unavailable — it is simply
ignored. The workflow would have looked gated while a merge to `main` applied
straight to the live server unattended. A safety mechanism that silently does
nothing is worse than no safety mechanism, because nobody checks it.

Making the repository public would restore all three features for free. That
was offered and declined; the repository stays private.

## Decision

Move the gate from GitHub's permission system into the workflow trigger.

- **Staging** applies automatically on a merge to `main`, unchanged.
- **Production** runs only from a manual `workflow_dispatch`, and only when
  three conditions all hold: the event is a dispatch, `target` is
  `production`, and the operator typed `APPLY` into the confirmation input.
  A first step additionally refuses to run from any ref other than `main`.

A `git push` cannot satisfy the first condition, so no merge can reach
production regardless of what else is true.

The `environment:` keys stay in the workflow. They do nothing today and cost
nothing, and they start enforcing the moment the repository goes public or the
plan changes.

## Consequences

- Production applies require a deliberate act by a human who had to choose an
  environment and type a word. For a one-person project this is close to what a
  required reviewer bought, since the reviewer would have been the author.
- The gate is now in a file in the repository, which is exactly what ADR 0003
  said to avoid. It can be weakened by a pull request that edits
  `apply.yml` — and with no branch protection, by a direct push to `main`.
  Accepted, because the alternative on this plan is no gate at all.
- CI cannot enforce that a plan was read before a merge. That check moves from
  the pipeline into the habits in `CONTRIBUTING.md`, which is a real downgrade:
  rules that hold only by willpower are the ones that lapse.
- Promotion is no longer one click away from a merge. Someone has to open the
  Actions tab and start the run, which is friction, and friction is the point.

## Alternatives considered

- **Make the repository public.** Restores required reviewers, branch
  protection and enforced `CODEOWNERS`, free. The repository was built to be
  publishable — no secrets, no account identifiers, guild IDs that are not
  sensitive. Declined by the owner; this ADR exists because of that choice, not
  in spite of it.
- **Pay for GitHub Pro.** Buys environments on private repositories, though the
  documentation suggests required reviewers may still need Enterprise. Not
  worth a subscription for a hobby server.
- **Leave `environment: production` as the gate and hope.** Rejected outright:
  it reads as protection and provides none.
- **Drop automated applies; run Terraform from the laptop.** Would make the
  pipeline pointless and put the only copy of the workflow in one person's
  shell history.
