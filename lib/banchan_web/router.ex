defmodule BanchanWeb.Router do
  use BanchanWeb, :router

  import BanchanWeb.UserAuth
  import Phoenix.LiveDashboard.Router
  import Surface.Catalogue.Router

  alias BanchanWeb.{BasicAuthPlug, EnsureEnabledPlug, EnsureRolePlug}

  @host Application.compile_env!(:banchan, [BanchanWeb.Endpoint, :url, :host])

  @content_security_policy (case Application.compile_env!(:banchan, :env) do
                              :prod ->
                                "default-src 'self' 'unsafe-eval' 'unsafe-inline';" <>
                                  "connect-src wss://#{@host} blob:;" <>
                                  "img-src 'self' blob: data:;" <>
                                  "font-src data:;"

                              # The cloudflare URLs are to get the Surface catalogue displaying right.
                              _ ->
                                "default-src 'self' 'unsafe-eval' 'unsafe-inline' https://cdnjs.cloudflare.com;" <>
                                  "connect-src ws://#{@host}:* blob:;" <>
                                  "img-src 'self' blob: data:;" <>
                                  "font-src data: https://cdnjs.cloudflare.com;"
                            end)

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {BanchanWeb.Layouts, :root})
    plug(:protect_from_forgery)

    plug(:put_secure_browser_headers, %{
      "content-security-policy" => @content_security_policy
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

  pipeline :artist do
    plug(EnsureRolePlug, [:admin, :mod, :artist])
  end

  pipeline :ensure_enabled do
    plug(EnsureEnabledPlug, [])
  end

  pipeline :require_authed do
    plug(:require_authenticated_user)
  end

  pipeline :basic_authed do
    plug(BasicAuthPlug, [])
  end

  scope "/", BanchanWeb do
    live_session :users_only, on_mount: {BanchanWeb.UserLiveAuth, :users_only} do
      pipe_through([:basic_authed, :browser, :require_authed, :ensure_enabled])

      live("/denizens/:handle/edit", DenizenLive.Edit, :edit)

      live("/offerings/:handle/:offering_type/request", OfferingLive.Request, :new)

      live("/commissions", CommissionLive, :index)
      live("/commissions/:commission_id", CommissionLive, :show)

      live("/settings", SettingsLive, :edit)
      live("/mfa_setup", SetupMfaLive, :edit)

      live("/report_bug", ReportBugLive.New, :new)

      get(
        "/commissions/:commission_id/attachment/:upload_id",
        CommissionAttachmentController,
        :show
      )

      get(
        "/commissions/:commission_id/attachment/:upload_id/thumbnail",
        CommissionAttachmentController,
        :thumbnail
      )

      get(
        "/commissions/:commission_id/attachment/:upload_id/preview",
        CommissionAttachmentController,
        :preview
      )

      get("/settings/confirm_email/:token", UserSettingsController, :confirm_email)
      get("/settings/refresh_session/:return_to", UserSessionController, :refresh_session)

      get("/apply_artist_token/:token", ArtistTokenController, :confirm_artist)
    end
  end

  scope "/", BanchanWeb do
    live_session :artists_only, on_mount: {BanchanWeb.UserLiveAuth, :artists_only} do
      pipe_through([:basic_authed, :browser, :require_authed, :ensure_enabled, :artist])

      live("/offerings/:handle/:offering_type/edit", StudioLive.Offerings.Edit, :edit)

      live("/studios", StudioLive.Index, :index)
      live("/studios/new", StudioLive.New, :new)
      live("/studios/:handle/edit", StudioLive.Edit, :edit)
      live("/studios/:handle/settings", StudioLive.Settings, :show)
      live("/studios/:handle/payouts", StudioLive.Payouts, :index)
      live("/studios/:handle/payouts/:payout_id", StudioLive.Payouts, :show)
      live("/studios/:handle/offerings/new", StudioLive.Offerings.New, :new)

      get("/studios/:handle/settings/stripe", StripeDashboardController, :dashboard)
    end
  end

  scope "/", BanchanWeb do
    live_session :mods_only, on_mount: {BanchanWeb.UserLiveAuth, :mods_only} do
      pipe_through([:basic_authed, :browser, :require_authed, :ensure_enabled, :mod])

      live("/denizens/:handle/moderation", DenizenLive.Moderation, :edit)
      live("/studios/:handle/moderation", StudioLive.Moderation, :edit)
      live("/admin/requests", BetaLive.Requests, :index)
      live("/admin/denizens", DenizenLive.Index, :index)
      live("/admin/reports", ReportLive.Index, :index)
      live("/admin/reports/:id", ReportLive.Show, :show)
    end
  end

  scope "/", BanchanWeb do
    pipe_through(:browser)

    get("/images/:type/:id", PublicImageController, :image)

    get("/images/:type/:id/download", PublicImageController, :download)

    get("/studios/:handle/connect_to_stripe", StripeAccountController, :account_link)

    get("/confirm/:token", UserConfirmationController, :confirm)

    delete("/logout", UserSessionController, :delete)
    get("/force_logout", UserSessionController, :force_logout)
  end

  scope "/", BanchanWeb do
    live_session :default, on_mount: {BanchanWeb.UserLiveAuth, :default} do
      pipe_through([:basic_authed, :browser])

      live("/account_disabled", AccountDisabledLive, :show)
    end
  end

  scope "/", BanchanWeb do
    live_session :open_no_basic_auth, on_mount: {BanchanWeb.UserLiveAuth, :open} do
      pipe_through([:browser, :ensure_enabled])

      live("/", HomeLive, :index)

      live("/beta", BetaLive.Signup, :new)
      live("/beta/confirmation", BetaLive.Confirmation, :show)

      live("/about-us", StaticLive.AboutUs, :show)
      live("/contact", StaticLive.Contact, :show)
      live("/membership", StaticLive.Membership, :show)

      live("/privacy-policy", StaticLive.PrivacyPolicy, :show)
      live("/cookies-policy", StaticLive.CookiesPolicy, :show)
      live("/disputes-policy", StaticLive.DisputesPolicy, :show)
      live("/terms-and-conditions", StaticLive.TermsAndConditions, :show)
    end
  end

  scope "/", BanchanWeb do
    live_session :open, on_mount: {BanchanWeb.UserLiveAuth, :open} do
      pipe_through([:basic_authed, :browser, :ensure_enabled])

      live("/denizens/:handle", DenizenLive.Show, :show)
      live("/denizens/:handle/following", DenizenLive.Show, :following)

      live("/discover", DiscoverLive.Index, :index)
      live("/discover/:type", DiscoverLive.Index, :index)

      live("/offerings/:handle/:offering_type", OfferingLive.Show, :show)

      live("/studios/:handle", StudioLive.Shop, :show)
      live("/studios/:handle/followers", StudioLive.Followers, :index)
      live("/studios/:handle/about", StudioLive.About, :show)
      live("/studios/:handle/portfolio", StudioLive.Portfolio, :show)
      live("/studios/:handle/disabled", StudioLive.Disabled, :show)

      live("/confirm", ConfirmationLive, :show)

      live("/reset_password", ForgotPasswordLive, :edit)
      live("/reset_password/:token", ResetPasswordLive, :edit)
    end
  end

  scope "/", BanchanWeb do
    live_session :redirect_if_authed, on_mount: {BanchanWeb.UserLiveAuth, :redirect_if_authed} do
      pipe_through([:basic_authed, :browser, :redirect_if_user_is_authenticated])

      live("/login", LoginLive, :new)
      post("/login", UserSessionController, :create)

      live("/register", RegisterLive, :new)
      post("/register", UserRegistrationController, :create)
    end
  end

  scope "/", BanchanWeb do
    live_session :deactivated, on_mount: {BanchanWeb.UserLiveAuth, :deactivated} do
      pipe_through([:basic_authed, :browser, :require_authed])

      live("/reactivate", ReactivateLive, :show)
    end
  end

  scope "/auth", BanchanWeb do
    pipe_through :browser

    get "/:provider", UserOAuthController, :request
    get "/:provider/callback", UserOAuthController, :callback
  end

  scope "/api", BanchanWeb do
    post("/stripe_webhook", StripeWebhookController, :webhook)
    post("/stripe_connect_webhook", StripeConnectWebhookController, :webhook)
  end

  scope "/admin" do
    # Enable admin stuff dev/test side but restrict it in prod
    pipe_through([
      :basic_authed,
      :browser
      | if(Application.compile_env!(:banchan, :env) in [:dev, :test], do: [], else: [:admin])
    ])

    live_dashboard("/dashboard", metrics: BanchanWeb.Telemetry, ecto_repos: Banchan.Repo)
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)

    # Moved out of /admin until a Surface Catalogue bug is fixed. See below.
    # if Application.compile_env!(:banchan, :env) == :dev do
    #   surface_catalogue("/catalogue")
    # end
  end

  scope "/" do
    pipe_through([
      :basic_authed,
      :browser
    ])

    if Application.compile_env!(:banchan, :env) == :dev do
      surface_catalogue("/catalogue")
    end
  end
end
