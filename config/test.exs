use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bespoke, Bespoke.Repo,
  username: "postgres",
  password: "postgres",
  database: "bespoke_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

if System.get_env("GITHUB_ACTIONS") do
  config :bespoke, Bespoke.Repo,
    username: System.get_env("POSTGRES_USER"),
    password: System.get_env("POSTGRES_PASSWORD"),
    database: "bespoke_test#{System.get_env("MIX_TEST_PARTITION")}",
    hostname: "localhost"
end

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bespoke, BespokeWeb.Endpoint,
  http: [port: 4002],
  server: false

config :pow, Pow.Ecto.Schema.Password, iterations: 1

# Print only warnings and errors during test
config :logger, level: :warn
