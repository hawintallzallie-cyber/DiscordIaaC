# Production: the real server. Changes reach here only after they have been
# applied to staging on a merge to main, and only after a human approves the
# production job in the GitHub Environment.
#
# Set enable_community and enable_onboarding to true only once Discord's
# Community requirements are met -- see docs/runbooks/bootstrap.md step 8.

server_id   = "REPLACE_WITH_PRODUCTION_GUILD_ID"
server_name = "REPLACE_WITH_HER_SERVER_NAME"

enable_community  = false
enable_onboarding = false
