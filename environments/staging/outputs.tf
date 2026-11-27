output "role_ids" {
  description = "Managed role IDs."
  value       = module.server.role_ids
}

output "channel_ids" {
  description = "Managed channel IDs."
  value       = module.server.channel_ids
}

output "automod_rule_names" {
  description = "AutoMod rules under management."
  value       = module.server.automod_rule_names
}

output "community_features_enabled" {
  description = "Which Community-gated features this environment manages."
  value       = module.server.community_features_enabled
}
