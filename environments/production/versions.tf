terraform {
  required_version = ">= 1.8.0"

  required_providers {
    discord = {
      source = "smoketurner/discord"
      # Pinned exactly in root modules. The provider is pre-1.0, so a minor
      # release can break. Dependabot opens a PR when a new version lands and
      # CI runs a plan against staging before anyone merges it.
      version = "0.4.0"
    }
  }

  # Deliberately empty. The organization comes from TF_CLOUD_ORGANIZATION and
  # the workspace from TF_WORKSPACE, so neither is committed and the same code
  # can be pointed at a different HCP account without a diff.
  cloud {}
}
