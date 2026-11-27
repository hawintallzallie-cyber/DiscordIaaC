module "server" {
  source = "../../modules/discord-server"

  server_id   = var.server_id
  server_name = var.server_name
  environment = "staging"

  enable_community  = var.enable_community
  enable_onboarding = var.enable_onboarding
}
