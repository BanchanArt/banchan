# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_username = System.get_env("DATABASE_USERNAME") || "postgres"

database_password = System.get_env("DATABASE_PASSWORD") || "postgres"

# Configure your database
config :banchan, Banchan.Repo,
  username: database_username,
  password: database_password,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :banchan, BanchanWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
