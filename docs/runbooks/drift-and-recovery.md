# Runbook: drift and recovery

## Someone changed something in the Discord UI

This will happen. It is not a bug — it is the known cost of ADR 0001.

**What happens:** the next `terraform plan` shows a diff reverting their change.
The next apply reverts it.

**What to do:** decide whether the change was a good idea.

- **It was a good idea** → put it in the repository through a pull request, so
  the next apply stops fighting it.
- **It was not** → let the next apply revert it, and tell whoever made it that
  the server is managed in Git.

**What not to do:** do not `terraform state rm` to make a diff go away. That
abandons the resource — Terraform forgets it exists, and the next apply tries to
create a second channel with the same name.

### Why the Moderator role cannot cause this

`roles.tf` deliberately withholds `MANAGE_CHANNELS`, `MANAGE_ROLES`,
`MANAGE_GUILD` and `MANAGE_WEBHOOKS` from Moderator. Moderators can moderate
people; they cannot restructure the server. Only Admin and the bot can, which
keeps the set of people who can cause drift down to the people who know the
repository exists.

---

## The plan wants to destroy something I did not touch

Usually one of three things:

1. **A `for_each` key changed.** Renaming a key in
   `local.announce_only_channels` destroys the old overwrite and creates a new
   one. Harmless for overwrites; it would not be for channels.
2. **A provider upgrade changed a schema.** Check whether a Dependabot PR is in
   play. This is exactly what pinning in ADR 0002 is for — roll back the version
   and reopen the upgrade separately.
3. **Something was deleted in Discord by hand.** Terraform plans to recreate it,
   which is correct, but the recreated channel is empty. The messages are gone
   and Terraform cannot bring them back.

---

## The apply failed halfway

Terraform applies resource by resource, so a failure leaves the server
partially changed. State reflects what actually succeeded, so the fix is
normally to fix the cause and run again.

Common causes, in rough order of likelihood:

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Missing Permissions` on a role resource | The bot's role is not above `Admin` | Drag the bot's role to the top (bootstrap step 5) |
| `Missing Permissions` on a channel overwrite | The bot lacks the permission it is granting | Re-invite with `permissions=8` (bootstrap step 4) |
| Onboarding rejected | Fewer than 7 default channels, or fewer than 5 that `@everyone` can post in | Add channels to `local.default_channel_ids` |
| Community-related failure | Community not enabled, or no rules / updates channel | Bootstrap step 11, in that order |
| `429` rate limited | Too many resources changed at once | Re-run; the provider honours retry headers |
| State lock stuck after a cancelled run | The lock is still held in HCP | Cancel the run in the HCP UI, or `terraform force-unlock LOCK_ID` |

---

## Rolling back a change

Reverting is a normal pull request:

```powershell
gh pr list --state merged --limit 5
```

```powershell
git revert --no-commit <merge-commit>; git switch -c revert/bad-change; git commit -m "revert: undo the thing"
```

Then open a PR, read the plan, merge, approve production.

**What a revert cannot undo:** anything Discord deleted. If the bad change
destroyed a channel, reverting recreates an empty channel with the same name.
Message history does not come back. This is why the "does the plan destroy
anything?" checkbox exists.

---

## Rebuilding staging from scratch

Staging is disposable, and rebuilding it is the fastest way to prove the
configuration still works from zero.

```powershell
cd environments/staging; terraform destroy
```

Then delete the Discord server in the UI, create a fresh one, put the new guild
ID in `terraform.tfvars`, and apply.

Do not do this in production. `terraform destroy` on the real server deletes
every channel and every message in them.

---

## Recovering state

HCP Terraform keeps a version history per workspace. If state is corrupted or
a resource was removed by mistake, roll back to an earlier state version in the
HCP UI rather than hand-editing anything.

If state is lost entirely, the server still exists — it just is not managed any
more. Every resource in this configuration documents its `terraform import`
syntax in the provider docs, so recovery means importing roughly 45 resources
one at a time. Unpleasant, not fatal. This is the argument for not keeping
state on one laptop.
