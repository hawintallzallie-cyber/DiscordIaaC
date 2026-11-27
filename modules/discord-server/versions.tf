terraform {
  # Provider-defined functions (provider::discord::permissions, ::color) were
  # introduced in Terraform 1.8. This module cannot work on anything older.
  required_version = ">= 1.8.0"

  required_providers {
    discord = {
      source = "smoketurner/discord"
      # The provider is pre-1.0, so a minor bump may break. Bound it to 0.4.x
      # here and pin the exact patch in each environment's root module.
      version = "~> 0.4.0"
    }
  }
}
