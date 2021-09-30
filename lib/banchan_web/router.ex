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

    live "/denizens/:at/edit", DenizenLive.Edit, :edit

    live "/studios/new", StudioLive.New, :new
    live "/studios/:at/edit", StudioLive.Edit, :edit
    live "/studios/:at/commissions/new", CommissionLive.New, :new
    live "/studios/:at/commissions/:id", CommissionLive.Show, :show

    live "/dashboard", DashboardLive, :index

    live "/settings", SettingsLive, :edit

    get "/settings/confirm_email/:token", UserSettingsController, :confirm_email
    get "/settings/refresh_session/:return_to", UserSessionController, :refresh_session
  end

  scope "/", BanchanWeb do
    pipe_through :browser

    live "/", HomeLive, :index

    live "/denizens/:at", DenizenLive.Show, :show
    live "/studios", StudioLive.Index, :index
    live "/studios/:at", StudioLive.Show, :show

    live "/confirm", ConfirmationLive, :show
    get "/confirm/:token", UserConfirmationController, :confirm

    delete "/logout", UserSessionController, :delete
    get "/force_logout", UserSessionController, :force_logout
  end

  scope "/", BanchanWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/login", LoginLive, :new
    post "/login", UserSessionController, :create

    live "/register", RegisterLive, :new
    post "/register", UserRegistrationController, :create

    live "/reset_password", ForgotPasswordLive, :edit

    live "/reset_password/:token", ResetPasswordLive, :edit
  end

  scope "/admin" do
    # Enable admin stuff dev/test side but restrict it in prod
    pipe_through [:browser | if(Mix.env() in [:dev, :test], do: [], else: [:admin])]

    live_dashboard "/dashboard", metrics: BanchanWeb.Telemetry, ecto_repos: Banchan.Repo
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end
end
