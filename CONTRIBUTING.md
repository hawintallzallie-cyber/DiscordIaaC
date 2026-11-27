# Contributing

Written as if for a team, because the point of the project is to practise
working the way a team works. Right now the team is one person, so some of this
reads as theatre. Do it anyway — the habits are the deliverable.

## The loop

1. An issue describes the change in plain language.
2. A branch off `main`: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`.
3. Commits in conventional form: `feat(channels): add a recipes channel`.
4. A pull request, filled in from the template.
5. CI posts a plan for staging and production. **Read both.**
6. Approve, merge. Staging applies automatically.
7. Look at the staging server. Then run the `apply` workflow by hand:
   **Actions → apply → Run workflow**, target `production`, confirm `APPLY`.

Step 6 is the one that matters, and on this repository nothing enforces it.
Branch protection is unavailable on a private repo on GitHub Free, so GitHub
will let you merge with a failing plan and no review. The plan comment is still
the only place where "this will delete a channel" is visible — reading it is
now a habit rather than a gate. See [ADR 0007](docs/adr/0007-manual-trigger-gate-on-a-private-repo.md).

## Where changes go

Almost always `modules/discord-server/`. The `environments/` directories exist
to differ in four values — guild ID, server name, and two Community flags.

If you are about to add a resource to one environment and not the other, stop:
it probably wants to be a module variable with a different default.

## Non-negotiables

- **No secrets in the repository.** The bot token lives in `.env` locally
  (gitignored) and in GitHub Secrets. It never goes in a `.tf` or `.tfvars`
  file. Guild IDs are not secrets and are committed deliberately.
- **`terraform fmt -recursive` before pushing.** It is a required status check.
- **Never `terraform apply` production from a laptop.** CI applies production,
  through the approval gate. A local apply skips the gate, skips the plan
  comment, and leaves no record of who did it.
- **Never `terraform state rm` to silence a diff.** It abandons the resource and
  the next apply creates a duplicate. See the drift runbook.
- **Read `destroy` and `must be replaced` lines twice.** Deleting a Discord
  channel deletes its message history. Nothing brings it back — not a revert,
  not a state rollback.

## Writing an ADR

Write one when a choice has a plausible alternative that a reasonable person
would have picked. Not for every change — six ADRs cover a project this size.

Copy `docs/adr/0000-template.md`, take the next number, and fill in the
**Consequences** section honestly. An ADR that lists only benefits is
marketing, and the costs are the part that is useful later.

Supersede rather than edit: set the old one's status to
`Superseded by ADR-XXXX` and leave its reasoning intact. The point of the
record is to show what was known at the time.

## Reviewing

With one contributor you will be approving your own pull requests. Make the
review real by changing what you look at:

- Does the plan match what the PR description claims?
- Is anything destroyed or replaced?
- If this changes permissions, who gains access that did not have it?
- If this changes moderation, is the reasoning written down anywhere?
- Would someone reading this in six months know why?

`enforce_admins` is left off in branch protection so you are not locked out of
your own repository. That is a convenience, and it means the rules hold only
because you choose to follow them.

## Local commands

```powershell
.\scripts\Load-Env.ps1
```

```powershell
terraform fmt -recursive
```

```powershell
cd environments/staging; terraform init; terraform plan
```

```powershell
tflint --recursive
```
