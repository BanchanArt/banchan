defmodule BanchanWeb.Router do
  use BanchanWeb, :router

  import BanchanWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  alias BanchanWeb.EnsureRolePlug

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {BanchanWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    # NB(zkat): unsafe-eval has to be enabled because webpack does it for its internals.
    plug(:put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self' 'unsafe-eval'; style-src data: 'self' 'unsafe-inline'; script-src data: 'self' 'unsafe-inline' 'unsafe-eval'; object-src data: 'unsafe-eval'; font-src data: 'unsafe-eval'; img-src data: 'self'; connect-src 'self'"
    })

    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :admin do
    plug(EnsureRolePlug, :admin)
  end

  pipeline :mod do
    plug(EnsureRolePlug, [:admin, :mod])
  end

  pipeline :creator do
    plug(EnsureRolePlug, [:admin, :mod, :creator])
  end

  scope "/", BanchanWeb do
    pipe_through([:browser, :require_authenticated_user])

    live("/denizens/:handle/edit", DenizenLive.Edit, :edit)

    live("/studios/new", StudioLive.New, :new)
    live("/studios/:handle/settings", StudioLive.Settings, :show)
    live("/studios/:handle/offerings", StudioLive.Offerings.Index, :index)
    live("/studios/:handle/offerings/new", StudioLive.Offerings.New, :new)
    live("/studios/:handle/offerings/edit/:offering_type", StudioLive.Offerings.Edit, :edit)
    live("/studios/:handle/commissions/new/:offering_type", StudioLive.Commissions.New, :new)
    live("/studios/:handle/commissions/:commission_id", StudioLive.Commissions.Show, :show)

    get(
      "/studios/:handle/commissions/:commission_id/attachment/:key",
      CommissionAttachmentController,
      :show
    )

    get(
      "/studios/:handle/commissions/:commission_id/attachment/:key/thumbnail",
      CommissionAttachmentController,
      :thumbnail
    )

    live("/dashboard", DashboardLive, :index)

    live("/settings", SettingsLive, :edit)
    live("/mfa_setup", SetupMfaLive, :edit)

    get("/settings/confirm_email/:token", UserSettingsController, :confirm_email)
    get("/settings/refresh_session/:return_to", UserSessionController, :refresh_session)
  end

  scope "/", BanchanWeb do
    pipe_through(:browser)

    live("/", HomeLive, :index)

    live("/denizens/:handle", DenizenLive.Show, :show)
    get("/denizens/:handle/pfp.jpeg", ProfileImageController, :pfp)
    get("/denizens/:handle/pfp_thumb.jpeg", ProfileImageController, :thumb)
    get("/denizens/:handle/header.jpeg", ProfileImageController, :header)

    live("/studios", StudioLive.Index, :index)
    live("/studios/:handle", StudioLive.Shop, :show)
    live("/studios/:handle/about", StudioLive.About, :show)
    live("/studios/:handle/portfolio", StudioLive.Portfolio, :show)
    live("/studios/:handle/qa", StudioLive.Qa, :show)
    get("/studios/:handle/connect_to_stripe", StripeAccountController, :account_link)

    live("/confirm", ConfirmationLive, :show)
    get("/confirm/:token", UserConfirmationController, :confirm)

    delete("/logout", UserSessionController, :delete)
    get("/force_logout", UserSessionController, :force_logout)
    get("/go/:handle", DispatchController, :dispatch)
  end

  scope "/", BanchanWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live("/login", LoginLive, :new)
    post("/login", UserSessionController, :create)

    live("/register", RegisterLive, :new)
    post("/register", UserRegistrationController, :create)

    live("/reset_password", ForgotPasswordLive, :edit)

    live("/reset_password/:token", ResetPasswordLive, :edit)
  end

  scope "/api", BanchanWeb do
    post("/stripe_webhook", StripeConnectWebhookController, :webhook)
  end

  scope "/admin" do
    # Enable admin stuff dev/test side but restrict it in prod
    pipe_through([:browser | if(Mix.env() in [:dev, :test], do: [], else: [:admin])])

    live_dashboard("/dashboard", metrics: BanchanWeb.Telemetry, ecto_repos: Banchan.Repo)
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
