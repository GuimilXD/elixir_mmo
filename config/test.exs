import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elixir_mmo, ElixirMmoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "kOlpG6XZLz1DZqqHDnxIwfylHH60eg1rDWpgEexBJS7NZwxKB2aa2RxtCqdwwVkC",
  server: false

# In test we don't send emails.
config :elixir_mmo, ElixirMmo.Mailer,
  adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

config :elixir_mmo, hero_respawn_delay: 50

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
