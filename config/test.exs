use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :pbkdf2_elixir, :rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :banchan, Banchan.Repo,
  username: "postgres",
  password: "postgres",
  database: "banchan_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

if System.get_env("GITHUB_ACTIONS") do
  config :banchan, Banchan.Repo,
    username: System.get_env("POSTGRES_USER"),
    password: System.get_env("POSTGRES_PASSWORD"),
    database: "banchan_test#{System.get_env("MIX_TEST_PARTITION")}",
    hostname: "localhost"
end

config :banchan, Banchan.Mailer,
  adapter: Bamboo.TestAdapter

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :banchan, BanchanWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
