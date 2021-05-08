defmodule ErotiCat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ErotiCat.Repo,
      # Start the Telemetry supervisor
      ErotiCatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ErotiCat.PubSub},
      # Start the Endpoint (http/https)
      ErotiCatWeb.Endpoint,
      # Cache sessions to Mnesia
      Pow.Store.Backend.MnesiaCache
      # Start a worker by calling: ErotiCat.Worker.start_link(arg)
      # {ErotiCat.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ErotiCat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ErotiCatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
