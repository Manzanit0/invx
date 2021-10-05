import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :nous, Nous.Repo,
  username: "postgres",
  password: "postgres",
  database: "nous_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 20

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :nous, NousWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
