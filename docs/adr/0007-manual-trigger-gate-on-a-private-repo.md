# ADR 0007: Gate production with a manual trigger, not a GitHub Environment

- **Status:** Accepted, amended the same day
- **Date:** 2026-11-27
- **Amends:** [ADR 0003](0003-two-guilds-staging-and-production.md)

> ## Update, 2026-11-27 (same day)
>
> **The repository was created public, not private.** Branch protection,
> environment protection rules and enforced `CODEOWNERS` are therefore all
> available on the free plan after all, and the constraint this ADR was written
> under no longer applies.
>
> **The manual-dispatch gate is kept anyway.** It does not depend on a plan
> tier, it cannot silently stop working, and it survives the repository being
> made private later — which, as the body of this ADR records, would disable
> protection rules without mentioning it.
>
> **Branch protection is now turned on as well**, because it does a genuinely
> different job: the dispatch gate stops a merge reaching production, while
> branch protection stops a *merge happening at all* without passing `validate`,
> `plan` and a code owner review. That check has no equivalent in the workflow.
>
> **Environment required reviewers are deliberately left off.** They would be a
> third confirmation of the same thing the dispatch gate already confirms, and
> redundant friction gets routed around rather than respected.
>
> The analysis below is kept unedited. The failure it describes was real, and
> the reasoning is the point: *verify that a control is enforced, not merely
> configured.*

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
