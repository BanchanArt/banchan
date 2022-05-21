# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# Load environment variables
if File.exists?(".env.ps1") and System.find_executable("powershell") do
  IO.puts("Loading .env.ps1")
  System.cmd("powershell", [".env.ps1"])
end

if File.exists?(".env") and System.find_executable("source") do
  IO.puts("Loading .env")
  System.cmd("source", [".env"])
end

# General application configuration
import Config

config :banchan,
  namespace: Banchan,
  ecto_repos: [Banchan.Repo],
  upload_dir: Path.expand("../priv/uploads", __DIR__),
  default_platform_fee: System.get_env("BANCHAN_PLATFORM_FEE") || 0.07

# Configures the endpoint
config :banchan, BanchanWeb.Endpoint,
  url: [host: "localhost"],
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

config :ex_aws,
  region: {:system, "AWS_REGION"},
  bucket: {:system, "S3_BUCKET_NAME"}

config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/images --external:favicon.ico --external:robots.txt),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :stripity_stripe,
  api_key: System.get_env("STRIPE_SECRET"),
  endpoint_secret: System.get_env("STRIPE_ENDPOINT_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
