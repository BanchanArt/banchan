# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :banchan,
  namespace: Banchan,
  ecto_repos: [Banchan.Repo]

# Configures the endpoint
config :banchan, BanchanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wE/ZQmiSLP77ZAfprMlRRB1D+JP9p2/wMrLhjVXyB8U6/JpoxWfWCsoE4bm3IoY/",
  render_errors: [view: BanchanWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Banchan.PubSub,
  live_view: [signing_salt: "qB2PgmVY"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :surface, :components, [
  {Surface.Components.Form.ErrorTag,
   default_translator: {BanchanWeb.ErrorHelpers, :translate_error}}
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
