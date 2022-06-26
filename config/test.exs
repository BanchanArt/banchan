import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :pbkdf2_elixir, :rounds, 1

config :banchan,
  stripe_mod: Banchan.StripeAPI.Mock

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
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  queue_target: 500

if System.get_env("GITHUB_ACTIONS") do
  config :banchan, Banchan.Repo,
    username: System.get_env("POSTGRES_USER"),
    password: System.get_env("POSTGRES_PASSWORD"),
    database: "banchan_test#{System.get_env("MIX_TEST_PARTITION")}",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10,
    # NOTE: For some reason, this was needed on Github Actions once we started
    # adding generated columns (for full text search). I don't know if this is
    # expected, but removing this should make tests fail pretty spectacularly
    # (but only on Github!) if you want to take a look.
    queue_target: 1000
end

config :banchan, Banchan.Mailer, adapter: Bamboo.TestAdapter

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :banchan, BanchanWeb.Endpoint,
  http: [port: 4002],
  server: false,
  secret_key_base: "wE/ZQmiSLP77ZAfprMlRRB1D+JP9p2/wMrLhjVXyB8U6/JpoxWfWCsoE4bm3IoY/"

# Print only warnings and errors during test
config :logger, level: :warn
