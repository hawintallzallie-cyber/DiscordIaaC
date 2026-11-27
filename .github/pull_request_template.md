## What changes in Discord

<!-- Describe the change as a member of the server would experience it, not as
a list of resources. "Adds a #looking-for-group channel visible to everyone"
beats "adds discord_text_channel.looking_for_group". -->

## Why

<!-- Link an issue, or say what prompted it. -->

## Plan review

- [ ] I read the `plan (staging)` comment on this PR
- [ ] I read the `plan (production)` comment on this PR
- [ ] The plan contains no unexpected `destroy` or `replace` actions
- [ ] If anything is being destroyed, I understand what is lost (channel
      message history does not come back)

## Checks

- [ ] `terraform fmt` is clean (CI enforces this)
- [ ] No tokens, secrets or `.env` contents are in the diff
- [ ] If this adds or removes channels, onboarding still has at least 7 default
      channels with at least 5 that @everyone can post in
- [ ] If this changes moderation, the reasoning is in the PR or an ADR

## Rollback

<!-- Usually "revert this PR and let apply run". Say so if it is not, for
example because the change destroys something Discord cannot restore. -->
