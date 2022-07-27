defmodule BanchanWeb.Router do
  use BanchanWeb, :router

  import BanchanWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  alias BanchanWeb.{EnsureEnabledPlug, EnsureRolePlug}

  @host Application.compile_env!(:banchan, [BanchanWeb.Endpoint, :url, :host])

  @content_security_policy (case Application.compile_env!(:banchan, :env) do
                              :prod ->
                                "default-src 'self' 'unsafe-eval' 'unsafe-inline'; connect-src wss://#{@host};img-src 'self' blob: data:; font-src data:;"

                              _ ->
                                "default-src 'self' 'unsafe-eval' 'unsafe-inline';" <>
                                  "connect-src ws://#{@host}:*;" <>
                                  "img-src 'self' blob: data:;"

                                "font-src data:;"
                            end)

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {BanchanWeb.LayoutView, :root})
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

  scope "/", BanchanWeb do
    live_session :users_only, on_mount: {BanchanWeb.UserLiveAuth, :users_only} do
      pipe_through([:browser, :require_authed, :ensure_enabled])

      live("/denizens/:handle/edit", DenizenLive.Edit, :edit)

      live("/offerings/:handle/:offering_type/request", OfferingLive.Request, :new)

      live("/commissions", CommissionLive, :index)
      live("/commissions/:commission_id", CommissionLive, :show)
      live("/commissions/:commission_id/receipt/:event_id", CommissionLive.Receipt, :show)

      live("/settings", SettingsLive, :edit)
      live("/mfa_setup", SetupMfaLive, :edit)

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
    end
  end

  scope "/", BanchanWeb do
    live_session :artists_only, on_mount: {BanchanWeb.UserLiveAuth, :artists_only} do
      pipe_through([:browser, :require_authed, :ensure_enabled, :artist])

      live("/offerings/:handle/:offering_type/edit", StudioLive.Offerings.Edit, :edit)

      live("/studios/new", StudioLive.New, :new)
      live("/studios/:handle/settings", StudioLive.Settings, :show)
      live("/studios/:handle/payouts", StudioLive.Payouts, :index)
      live("/studios/:handle/payouts/:payout_id", StudioLive.Payouts, :show)
      live("/studios/:handle/offerings/new", StudioLive.Offerings.New, :new)

      get("/studios/:handle/settings/stripe", StripeDashboardController, :dashboard)
    end
  end

  scope "/", BanchanWeb do
    live_session :mods_only, on_mount: {BanchanWeb.UserLiveAuth, :mods_only} do
      pipe_through([:browser, :require_authed, :ensure_enabled, :mod])

      live("/denizens/:handle/moderation", DenizenLive.Moderation, :edit)
      live("/studios/:handle/moderation", StudioLive.Moderation, :edit)
      live("/admin/denizens", DenizenLive.Index, :index)
      live("/admin/reports", ReportLive.Index, :index)
      live("/admin/reports/:id", ReportLive.Show, :show)
    end
  end

  scope "/", BanchanWeb do
    pipe_through(:browser)

    get("/go/:handle", DispatchController, :dispatch)

    get("/images/:id", PublicImageController, :image)

    get("/images/:id/download", PublicImageController, :download)

    get("/studios/:handle/connect_to_stripe", StripeAccountController, :account_link)

    get("/confirm/:token", UserConfirmationController, :confirm)

    delete("/logout", UserSessionController, :delete)
    get("/force_logout", UserSessionController, :force_logout)
  end

  scope "/", BanchanWeb do
    live_session :default, on_mount: {BanchanWeb.UserLiveAuth, :default} do
      pipe_through(:browser)

      live("/account_disabled", AccountDisabledLive, :show)
    end
  end

  scope "/", BanchanWeb do
    live_session :open, on_mount: {BanchanWeb.UserLiveAuth, :open} do
      pipe_through([:browser, :ensure_enabled])

      live("/", HomeLive, :index)

      live("/denizens/:handle", DenizenLive.Show, :show)
      live("/denizens/:handle/following", DenizenLive.Show, :following)

      live("/discover", DiscoverLive.Index, :index)
      live("/discover/:type", DiscoverLive.Index, :index)

      live("/offerings/:handle/:offering_type", OfferingLive.Show, :show)

      live("/studios/:handle", StudioLive.Shop, :show)
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
      pipe_through([:browser, :redirect_if_user_is_authenticated])

      live("/login", LoginLive, :new)
      post("/login", UserSessionController, :create)

      live("/register", RegisterLive, :new)
      post("/register", UserRegistrationController, :create)
    end
  end

  scope "/auth", BanchanWeb do
    pipe_through :browser

    get "/:provider", UserOAuthController, :request
    get "/:provider/callback", UserOAuthController, :callback
  end

  scope "/api", BanchanWeb do
    post("/stripe_webhook", StripeConnectWebhookController, :webhook)
  end

  scope "/admin" do
    # Enable admin stuff dev/test side but restrict it in prod
    pipe_through([
      :browser
      | if(Application.fetch_env!(:banchan, :env) in [:dev, :test], do: [], else: [:admin])
    ])

    live_dashboard("/dashboard", metrics: BanchanWeb.Telemetry, ecto_repos: Banchan.Repo)
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
