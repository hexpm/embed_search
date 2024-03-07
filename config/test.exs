import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :search, Search.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "search_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :search, SearchWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "KoDCWrF9SEsnoM8svaiDh9g62hqg8cKGhafXsTKunfl/FVMTq1psZAyOoMp3eIO2",
  server: false

# Enable testing plug for Req to enable stubs in HexClientTest
config :search,
  hex_client_req_options: [
    plug: {Req.Test, Search.HexClient}
  ]

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
