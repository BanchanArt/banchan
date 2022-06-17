# This is an example file for what dev.secret.exs should look like.
# Copy it and set the configuration as needed.

import Config

# Which port the server runs on
config :banchan, BanchanWeb.Endpoint,
  http: [port: 4000]

# Database configuration
config :banchan, Banchan.Repo,
  username: "postgres",
  password: "postgres",
  database: "banchan_dev",
  hostname: "localhost",
  pool_size: 10

# Stripe configuration
config :stripity_stripe,
  api_key: "",
  endpoint_secret: ""

# AWS configuration. If left unset,
# uploads will be saved to priv/uploads
#config :ex_aws,
  #bucket: "",
  #region: "us-west-1",
  #access_key_id: "",
  #secret_access_key: ""
