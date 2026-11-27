# Runbook: making a change

The everyday loop. Example: she asks for a channel for sharing recipes.

---

## 1. Write it down first

Open an issue, even for a small change, even though you are the only person
here. The issue is what the commit message and the pull request point back at,
and it is what makes the Git history readable six months later.

```powershell
gh issue create --title "Add a recipes channel" --body "Requested in chat. Public, under Community."
```

## 2. Branch

```powershell
git switch -c feat/recipes-channel
```

Branch names: `feat/`, `fix/`, `chore/`, `docs/`. Nothing enforces this; it just
keeps the branch list legible.

## 3. Change the module, not the environment

Almost every change belongs in `modules/discord-server/`. The two
`environments/` directories should keep differing only in guild ID, server name
and the Community flags — if you find yourself adding a resource to one
environment and not the other, stop and ask whether it should be a module
variable instead.

For a new text channel, in `channels.tf`:

```hcl
resource "discord_text_channel" "recipes" {
  server_id        = var.server_id
  category_id      = discord_category_channel.community.id
  name             = "recipes"
  topic            = "Things you cooked, and things you want to."
  audit_log_reason = local.audit_reason
}
```

Then decide, explicitly, about three things:

- **Is it a default channel?** If new members should land in it, add it to
  `local.default_channel_ids` in `main.tf`. Watch the floor: Discord requires
  at least 7 default channels with at least 5 that `@everyone` can post in.
- **Does it need permissions?** If it is read-only or staff-only, add it to the
  relevant map in `permissions.tf` rather than writing new resources.
- **Should it appear in outputs?** Add it to `channel_ids` in `outputs.tf` so
  it is visible in the plan output.

## 4. Format and check locally

```powershell
terraform fmt -recursive
```

```powershell
cd environments/staging; terraform plan
```

`terraform fmt` is a required status check, so an unformatted file fails CI
before anything else runs.

## 5. Open the pull request

```powershell
git add -A; git commit -m "feat(channels): add a recipes channel"
```

```powershell
git push -u origin HEAD; gh pr create --fill
```

Conventional commit prefixes (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`)
with a scope in brackets. Not enforced, but the history reads better and it is
the convention most teams you would join already use.

## 6. Read the plan comments

CI posts two comments: `plan (staging)` and `plan (production)`. Read both.

The checklist in the PR template asks whether anything is being destroyed. Take
that question seriously — this is the single check that catches the expensive
mistakes:

- `# discord_text_channel.general will be updated in-place` — fine.
- `# discord_text_channel.general must be replaced` — **stop**. Replacement
  deletes the channel and its entire message history. Find which argument
  forces it and change the approach.
- `# discord_text_channel.something will be destroyed` — only correct if you
  meant to delete that channel.

## 7. Merge, then approve production

Merging to `main` applies to staging automatically. Go and look at the staging
server before approving production — the whole reason staging exists is that
you get to check reality, not just a plan.

Then approve the `apply production` job in the Actions run.

## 8. Close the loop

```powershell
gh issue close 12 --comment "Shipped in #13."
```
