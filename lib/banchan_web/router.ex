defmodule BanchanWeb.Router do
  use BanchanWeb, :router

  import BanchanWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  alias BanchanWeb.EnsureRolePlug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BanchanWeb.LayoutView, :root}
    plug :protect_from_forgery
    # NB(zkat): unsafe-eval has to be enabled because webpack does it for its internals.
    plug :put_secure_browser_headers, %{
      "content-security-policy" => "default-src 'self' 'unsafe-eval'"
    }

    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug EnsureRolePlug, :admin
  end

  pipeline :mod do
    plug EnsureRolePlug, [:admin, :mod]
  end

  pipeline :creator do
    plug EnsureRolePlug, [:admin, :mod, :creator]
  end

  scope "/", BanchanWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/denizens/:handle/edit", DenizenEditLive, :edit
    live "/studios/new", StudioNewLive, :new
    live "/studios/:slug/edit", StudioEditLive, :edit
    live "/dashboard", DashboardLive, :index

    live "/settings", SettingsLive, :edit
    get "/settings/confirm_email/:token", UserSettingsController, :confirm_email
    get "/settings/refresh_session", UserSettingsController, :refresh_session
  end

  scope "/", BanchanWeb do
    pipe_through :browser

    live "/", HomeLive, :index

    live "/denizens/:handle", DenizenShowLive, :show
    live "/studios", StudioIndexLive, :index
    live "/studios/:slug", StudioShowLive, :show

    get "/force_logout", UserSessionController, :force_logout
  end

  scope "/admin" do
    # Enable admin stuff dev/test side but restrict it in prod
    pipe_through [:browser | if(Mix.env() in [:dev, :test], do: [], else: [:admin])]

    live_dashboard "/dashboard", metrics: BanchanWeb.Telemetry, ecto_repos: Banchan.Repo
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  ## Registration and Authentication routes

  scope "/", BanchanWeb do
    pipe_through [:browser]

    delete "/log_out", UserSessionController, :delete
    get "/confirm", UserConfirmationController, :new
    post "/confirm", UserConfirmationController, :create
    get "/confirm/:token", UserConfirmationController, :confirm
  end

  scope "/", BanchanWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/register", UserRegistrationController, :new
    post "/register", UserRegistrationController, :create
    get "/log_in", UserSessionController, :new
    post "/log_in", UserSessionController, :create
    get "/reset_password", UserResetPasswordController, :new
    post "/reset_password", UserResetPasswordController, :create
    get "/reset_password/:token", UserResetPasswordController, :edit
    put "/reset_password/:token", UserResetPasswordController, :update
  end
end
