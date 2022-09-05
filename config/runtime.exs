# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

if config_env() == :prod do
  case System.get_env("BASIC_AUTH_USERNAME") do
    nil ->
      nil

    username ->
      config :banchan,
        basic_auth: [username: username, password: System.get_env("BASIC_AUTH_PASSWORD")]
  end

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :banchan, Banchan.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :banchan, BanchanWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base

  stripe_secret =
    System.get_env("STRIPE_SECRET") ||
      raise """
      environment variable STRIPE_SECRET is missing.
      You can find your Stripe Secret Key at https://dashboard.stripe.com/apikeys
      """

  endpoint_secret =
    System.get_env("STRIPE_ENDPOINT_SECRET") ||
      raise """
      environment variable STRIPE_ENDPOINT_SECRET is missing.
      You can generate one by going to https://dashboard.stripe.com/webhooks and
      setting up the Stripe webhook according to the Banchan docs.
      """

  config :stripity_stripe,
    api_key: stripe_secret,
    endpoint_secret: endpoint_secret

  github_pat =
    System.get_env("GITHUB_PAT") ||
      raise """
      environment variable GITHUB_PAT is missing.
      You can generate one by going to https://github.com/settings/tokens.
      Must have `public_repo` scope.
      """

  config :banchan,
    github_access_token: github_pat

  dsn =
    System.get_env("SENTRY_DSN") ||
      raise """
      environment variable SENTRY_DSN is missing.
      Find the Sentry DSN at https://sentry.io/settings/{organization}/projects/elixir/keys/
      """

  config :sentry,
    dsn: dsn

  aws_region =
    System.get_env("AWS_REGION") ||
      raise """
      environment variable AWS_REGION is missing.
      It must be a valid region identifier (e.g. us-west-1)
      """

  aws_bucket =
    System.get_env("S3_BUCKET_NAME") ||
      raise """
      environment variable S3_BUCKET_NAME is missing.
      It must be the name of a pre-configured S3 bucket.
      """

  aws_access_key_id =
    System.get_env("AWS_ACCESS_KEY_ID") ||
      raise """
      environment variable AWS_ACCESS_KEY_ID is missing.
      """

  aws_secret_access_key =
    System.get_env("AWS_SECRET_ACCESS_KEY") ||
      raise """
      environment variable AWS_SECRET_ACCESS_KEY is missing.
      """

  config :ex_aws,
    region: aws_region,
    bucket: aws_bucket,
    access_key_id: aws_access_key_id,
    secret_access_key: aws_secret_access_key

  sendgrid_api_key =
    System.get_env("SENDGRID_API_KEY") ||
      raise """
      environment variable SENDGRID_API_KEY is missing.
      You can create one at https://app.sendgrid.com/settings/api_keys.
      """

  sendgrid_domain =
    System.get_env("SENDGRID_DOMAIN") ||
      raise """
      environment variable SENDGRID_DOMAIN is missing.
      You can set one up at https://app.sendgrid.com/settings/sender_auth/domain/create.
      """

  config :banchan, Banchan.Mailer,
    api_key: sendgrid_api_key,
    sendgrid_domain: sendgrid_domain

  discord_client_id =
    System.get_env("DISCORD_CLIENT_ID") ||
      raise """
      environment variable DISCORD_CLIENT_ID is missing.
      You can find your Discord Client ID at https://discordapp.com/developers/applications.
      """

  discord_client_secret =
    System.get_env("DISCORD_CLIENT_SECRET") ||
      raise """
      environment variable DISCORD_CLIENT_SECRET is missing.
      You can find your Discord Client Secret at https://discordapp.com/developers/applications.
      """

  config :ueberauth, Ueberauth.Strategy.Discord.OAuth,
    client_id: discord_client_id,
    client_secret: discord_client_secret

  twitter_consumer_key =
    System.get_env("TWITTER_CONSUMER_KEY") ||
      raise """
      environment variable TWITTER_CONSUMER_KEY is missing.
      You can find your Twitter Consumer Key at https://developer.twitter.com/en/portal/dashboard.
      You'll need an Elevated project.
      """

  twitter_consumer_secret =
    System.get_env("TWITTER_CONSUMER_SECRET") ||
      raise """
      environment variable TWITTER_CONSUMER_SECRET is missing.
      You can find your Twitter Consumer Secret at https://developer.twitter.com/en/portal/dashboard.
      You'll need an Elevated project.
      """

  config :ueberauth, Ueberauth.Strategy.Twitter.OAuth,
    consumer_key: twitter_consumer_key,
    consumer_secret: twitter_consumer_secret

  # TODO: Re-enable when we're ready to do google oauth again
  # google_client_id =
  #   System.get_env("GOOGLE_CLIENT_ID") ||
  #     raise """
  #     environment variable GOOGLE_CLIENT_ID is missing.
  #     You can find your Google Client ID at https://console.developers.google.com/apis/credentials.
  #     """

  # google_client_secret =
  #   System.get_env("GOOGLE_CLIENT_SECRET") ||
  #     raise """
  #     environment variable GOOGLE_CLIENT_SECRET is missing.
  #     You can find your Google Client Secret at https://console.developers.google.com/apis/credentials.
  #     """

  # config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  #   client_id: google_client_id,
  #   client_secret: google_client_secret
end
