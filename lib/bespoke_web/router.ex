defmodule BespokeWeb.Router do
  use BespokeWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {BespokeWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
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

    live("/", PageLive, :index)
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
end
