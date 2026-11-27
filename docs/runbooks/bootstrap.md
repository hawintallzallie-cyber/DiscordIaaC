# Runbook: bootstrap from nothing

One-time setup. After this, every change goes through a pull request.

Expect this to take about an hour. Steps 1–6 are local; steps 7–10 are GitHub
and HCP; step 11 is the first real apply.

---

## 1. Install the tooling

Neither of these was on the machine this repo was created on.

```powershell
winget install --id Hashicorp.Terraform -e
```

```powershell
winget install --id GitHub.cli -e
```

Close and reopen the terminal, then confirm:

```powershell
terraform version; gh --version
```

Terraform must be **1.8.0 or newer**. The configuration uses provider-defined
functions (`provider::discord::permissions`), which do not exist before 1.8.

---

## 2. Create the two Discord servers

Discord does not let bots create servers — `discord_server_settings` *adopts*
an existing guild. So both servers are made by hand, once.

1. In Discord, click the **+** in the server list → **Create My Own**.
   Name it something like `Server Lab (staging)`. This one is disposable.
2. Either create the real server the same way, or use the existing one if there
   already is one.
3. Turn on **Settings → Advanced → Developer Mode**.
4. Right-click each server icon → **Copy Server ID**. Keep both IDs; they go
   into the tfvars files in step 6.

Guild IDs are not secrets. They are committed deliberately.

---

## 3. Create the bot

1. Go to <https://discord.com/developers/applications> → **New Application**.
   Name it something recognisable in an audit log, e.g. `Terraform`.
2. Open the **Bot** tab.
3. **Reset Token**, then copy it. This is the only time it is shown.
4. Turn **off** "Public Bot" — nobody else should be able to invite it.
5. Leave the privileged intents off. Nothing in this configuration needs them.
   (Only the `discord_member` data source would, and it is not used.)

**The token is a credential with full control of both servers.** It goes in
`.env` locally and in GitHub Secrets. It never goes in a `.tf` or `.tfvars`
file, and never in a commit.

---

## 4. Invite the bot to both servers

Take the **Application ID** from the application's General Information tab and
open this URL once per server, substituting it in:

```
https://discord.com/api/oauth2/authorize?client_id=APPLICATION_ID&permissions=8&scope=bot
```

`permissions=8` is Administrator. That is deliberate, and it is a real decision
rather than laziness: Discord will not let a bot grant a permission through a
channel overwrite that the bot does not itself hold, *unless* it has
Administrator. Since `permissions.tf` grants permissions to the Moderator role,
anything less fails partway through an apply.

The consequence is that the bot token is the most sensitive thing in this
project. Treat it accordingly: if it leaks, reset it immediately (step 3) and
update the GitHub secret.

This OAuth click is the one step that cannot be automated — see ADR 0004.

---

## 5. Move the bot's role to the top

Still manual, and easy to forget.

**Server Settings → Roles**, drag the `Terraform` role to the very top of the
list. Do this in both servers.

Discord refuses to let a bot create or reorder a role above its own highest
role. `discord_role_positions` puts `Admin` at the top, so if the bot's role
sits below `Admin`, the apply fails with a permissions error that does not
obviously say "drag a role upward".

---

## 6. Fill in the guild IDs

Replace the placeholders:

- `environments/staging/terraform.tfvars` → `server_id`
- `environments/production/terraform.tfvars` → `server_id` and `server_name`

Until you do, `terraform plan` fails immediately with the validation message
from `modules/discord-server/variables.tf`. That is intentional — it fails at
plan time with a clear explanation rather than at apply time with a Discord
API error.

Leave `enable_community` and `enable_onboarding` as `false` for now. Step 11
turns them on.

---

## 7. Set up HCP Terraform state

1. Sign up at <https://app.terraform.io> (free tier is enough) and create an
   organization.
2. Create two workspaces, both of type **CLI-driven workflow**:
   - `discord-staging`
   - `discord-production`
3. In each workspace: **Settings → General → Execution Mode → Local**.

   This matters. In the default *Remote* mode, HCP runs Terraform on its own
   servers and would need its own copy of `DISCORD_TOKEN`. In *Local* mode HCP
   only stores state and holds the lock, and the bot token stays in GitHub
   Secrets alone. See ADR 0006.
4. Create a user API token: **User Settings → Tokens → Create an API token**.
   This is `TF_API_TOKEN` in step 9.

---

## 8. Set up local environment variables

```powershell
Copy-Item .env.example .env
```

Fill in `DISCORD_TOKEN`, `TF_CLOUD_ORGANIZATION` and `TF_WORKSPACE`. `.env` is
gitignored.

PowerShell does not read `.env` by itself. Load it for the current session:

```powershell
.\scripts\Load-Env.ps1
```

Then authenticate the Terraform CLI to HCP:

```powershell
terraform login
```

---

## 9. Create the GitHub repository

**The GitHub CLI cannot be installed on this machine.** `winget` ships `gh`
only as an MSI (installer type `wix`), and MSI installs are blocked here by
machine policy — the install fails with exit code **1625**,
`ERROR_INSTALL_POLICY_FAILURE`. Terraform and tflint installed fine because
they are ZIP packages.

So the repository is created in a browser, and Git Credential Manager (already
installed with Git for Windows) handles authentication on first push.

1. Go to <https://github.com/new>.
2. Name it, set visibility, and leave **Add a README**, **Add .gitignore** and
   **Add license** all off. Any of the three creates an initial commit on
   GitHub's side, and the local history then has no common ancestor with it —
   the push is rejected, and the only ways out are a force-push or a merge with
   `--allow-unrelated-histories`.
3. Add the remote and push:

```powershell
git remote add origin https://github.com/OWNER/REPO.git
```

```powershell
git push -u origin main
```

The first push opens a Git Credential Manager browser window. Sign in there.

**Secrets and variables** normally go in with `gh secret set`. Without the CLI,
add them by hand under **Settings → Secrets and variables → Actions**:

| Name | Kind | Value |
| --- | --- | --- |
| `DISCORD_TOKEN` | Secret | The bot token from step 3 |
| `TF_API_TOKEN` | Secret | The HCP user API token from step 7 |
| `TF_CLOUD_ORGANIZATION` | Variable | Your HCP organization name |

If you ever want the CLI anyway, the official ZIP build sidesteps the MSI
policy — download `gh_<version>_windows_amd64.zip` from
<https://github.com/cli/cli/releases> and extract it somewhere on your PATH.

---

## 10. Turn on the guard rails

The repository is **public**, so all of these are available on the free plan.
They would not have been on a private repo — [ADR 0007](../adr/0007-manual-trigger-gate-on-a-private-repo.md)
explains why that matters and what nearly went wrong.

**Two layers, doing different jobs:**

| Layer | What it stops | Where it lives |
| --- | --- | --- |
| Manual dispatch gate | A merge reaching **production** | `apply.yml` — already in the repo |
| Branch protection | A **merge happening at all** without a passing plan and a review | GitHub settings — turn on below |

**Branch protection on `main`** — Settings → Branches → Add rule, or, if you
ever get the `gh` CLI working:

```powershell
gh api -X PUT repos/:owner/:repo/branches/main/protection --input .github/branch-protection.json
```

What to require:

- Pull request before merging, 1 approval, dismiss stale approvals
- **Require review from Code Owners** — this is what makes `CODEOWNERS` real
- Require status checks: `terraform fmt`, `validate (module)`,
  `validate (staging)`, `validate (production)`, `tflint`, `plan (staging)`,
  `plan (production)`
- Require branches to be up to date before merging
- Require conversation resolution

`.github/branch-protection.json` is already written with those check names.
The checks must have run at least once before GitHub will let you select them,
so open the first pull request before configuring this.

**Environment required reviewers are deliberately not used.** They would be a
third confirmation of what the dispatch gate already requires, and redundant
friction gets routed around rather than respected.

Approving your own pull requests feels silly with one contributor. Do it
anyway — the point is that nothing reaches the live server without the plan
having been read.

> **If you ever switch this repository to private**, GitHub drops branch
> protection and ignores environment rules *without telling you*. The dispatch
> gate in `apply.yml` would keep working; nothing else here would.

---

## 11. First apply, then enable Community

Apply to staging from your laptop first, so you see the plan in full before CI
ever runs:

```powershell
cd environments/staging; terraform init; terraform plan
```

Read the plan. It should create roughly 45 resources and destroy nothing. Then:

```powershell
terraform apply
```

Open the staging server and look at it. Check that `#staff-chat` is invisible to
an alt account, that `#rules` is read-only, and that AutoMod rules appear under
Server Settings → AutoMod.

Then commit, push, and open the first pull request so the pipeline runs end to
end.

**Only once production has been applied at least once**, enable Community:

1. In the real server: **Server Settings → Enable Community** and complete
   Discord's checklist. It will ask for a rules channel and a community updates
   channel; pick `#rules` and `#mod-log`, which already exist by then.
2. Set both flags to `true` in `environments/production/terraform.tfvars`.
3. Open a pull request. Read the plan — it should *create*
   `discord_onboarding.main[0]` and `discord_welcome_screen.main[0]` and update
   `discord_server_settings.main`.
4. Merge, approve the production job.

The order matters: onboarding requires Community, and Community requires the
rules and updates channels to exist. Trying to do all of it in one apply fails
halfway, leaving Community on and onboarding missing.
