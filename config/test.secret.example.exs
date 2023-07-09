# This is an example file for what test.secret.exs should look like. Copy it
# and set the configuration if/as needed.
#
# The file is usually only really needed if your postgres config is different
# from what's in test.exs, but you can use it to override other configs.

import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :banchan, Banchan.Repo,
  username: "myuser",
  password: "mypassword",
  hostname: "localhost"
