# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :banchan,
  env: config_env(),
  deploy_env: config_env(),
  namespace: Banchan,
  stripe_mod: Banchan.StripeAPI,
  ecto_repos: [Banchan.Repo],
  upload_dir: Path.expand("../priv/uploads", __DIR__),
  default_platform_fee: System.get_env("BANCHAN_PLATFORM_FEE") || 0.1,
  max_attachment_size: 25_000_000,
  mature_content_enabled?: true

# Configures the endpoint
config :banchan, BanchanWeb.Endpoint,
  render_errors: [
    formats: [html: BanchanWeb.ErrorHTML, json: BanchanWeb.ErrorJSON],
    layout: false
  ],
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

config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/images --external:favicon.ico --external:robots.txt --external:/.well-known),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    # ],
    # catalogue: [
    #   args:
    #     ~w(../deps/surface_catalogue/assets/js/app.js --bundle --target=es2016 --minify --outdir=../priv/static/assets/catalogue),
    #   cd: Path.expand("../assets", __DIR__),
    #   env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :ueberauth, Ueberauth,
  providers: [
    discord:
      {Ueberauth.Strategy.Discord,
       [
         default_scope: "identify email"
       ]},
    google: {Ueberauth.Strategy.Google, []}
  ]

config :banchan, Oban,
  repo: Banchan.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    Oban.Plugins.Reindexer,
    Oban.Plugins.Lifeline,
    {Oban.Plugins.Cron,
     crontab: [
       {"@daily", Banchan.Workers.Pruner}
     ]}
  ],
  queues: [mailers: 10, media: 2, unban: 10, pruning: 1, invoice_purge: 10, upload_cleanup: 10]

config :sentry,
  included_environments: [:prod, :staging, :dev],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: config_env()
  },
  environment_name: config_env()

config :logger, Sentry.LoggerBackend, capture_log_messages: true

config :surface, :components, [
  {BanchanWeb.Components.Form.Checkbox, propagate_context_to_slots: true},
  {BanchanWeb.Components.Form.TextArea, propagate_context_to_slots: true}
]

config :stripity_stripe, api_version: "2020-08-27"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
