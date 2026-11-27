# Staging: a throwaway server used to prove a change works before it touches
# the real one. Community stays off so this environment can be deleted and
# rebuilt from scratch without re-qualifying for Community every time.
#
# Guild IDs are not secrets, so they are committed. Replace the placeholder
# below with your staging server's ID -- until you do, `terraform plan` fails
# fast with the validation message from modules/discord-server/variables.tf.

server_id   = "REPLACE_WITH_STAGING_GUILD_ID"
server_name = "Server Lab (staging)"

enable_community  = false
enable_onboarding = false
