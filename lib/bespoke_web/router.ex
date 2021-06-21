defmodule BespokeWeb.Router do
  use BespokeWeb, :router

  import BespokeWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {BespokeWeb.LayoutView, :root})
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

  pipeline :logged_in do
  end

  pipeline :admin do
  end

  pipeline :mod do
  end

  pipeline :creator do
  end

  scope "/", BespokeWeb do
    pipe_through(:browser)

    live "/", PageLive, :index
  end

  scope "/settings", BespokeWeb do
    pipe_through([:browser, :logged_in])
  end

  scope "/admin" do
    # Enable admin stuff dev/test side but restrict it in prod
    pipe_through([:browser | if(Mix.env() in [:dev, :test], do: [], else: [:admin])])

    live_dashboard "/dashboard", metrics: BespokeWeb.Telemetry, ecto_repos: Bespoke.Repo
  end

  # scope "/api", BespokeWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/", BespokeWeb do
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

  scope "/", BespokeWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", BespokeWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
