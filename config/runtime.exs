# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :banchan, Banchan.Repo,
    # ssl: true,
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
end
