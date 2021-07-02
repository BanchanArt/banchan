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
      "content-security-policy" => "default-src 'self' 'unsafe-eval'"
    })

    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
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
    pipe_through(:browser)

    live "/", HomeLive, :index
    live "/profiles/:user", ProfileLive, :index

    get "/users/force_logout", UserSessionController, :force_logout
  end

  scope "/settings", BanchanWeb do
    pipe_through([:browser, :logged_in])
  end

  scope "/admin" do
    # Enable admin stuff dev/test side but restrict it in prod
    pipe_through([:browser | if(Mix.env() in [:dev, :test], do: [], else: [:admin])])

    live_dashboard "/dashboard", metrics: BanchanWeb.Telemetry, ecto_repos: Banchan.Repo
  end

  # scope "/api", BanchanWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/", BanchanWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", BanchanWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", BanchanWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
