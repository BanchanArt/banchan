defmodule BanchanWeb.Endpoint do
  # Captures errors in the Plug stack and send them to Sentry.io
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :banchan

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_banchan_key",
    signing_salt: "sgxg5EhZ",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in offeringion.
  plug Plug.Static,
    at: "/",
    from: :banchan,
    gzip: false,
    only: BanchanWeb.static_paths(),
    # Fuck AI
    headers: [{"x-robots-tag", "noai"}]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :banchan
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    body_reader: {BanchanWeb.CacheBodyReader, :read_body, []},
    json_decoder: Phoenix.json_library()

  # Adds contextual information to errors captured by Sentry, should be under Plug.Parsers
  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # Reject AI as much as possible
  plug BanchanWeb.FuckAiPlug

  plug BanchanWeb.Router
end
