defmodule Banchan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Banchan.Workers.Utils

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Banchan.Repo,
      # Start the Telemetry supervisor
      BanchanWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Banchan.PubSub},
      # Start the Endpoint (http/https)
      BanchanWeb.Endpoint,
      # Start the Task supervisor for handling notifications
      {Task.Supervisor, name: Banchan.NotificationTaskSupervisor},
      # Start Oban
      {Oban, Application.fetch_env!(:banchan, Oban)},
      # Start a worker by calling: Banchan.Worker.start_link(arg)
      # {Banchan.Worker, arg}
      # GenServer for managing foreign exchange rate fetching.
      {Banchan.Payments.Forex,
       name: Banchan.Payments.Forex, base_currency: Banchan.Payments.platform_currency()}
    ]

    :ok = Oban.Telemetry.attach_default_logger()

    :telemetry.attach(
      "oban-errors",
      [:oban, :job, :exception],
      &Utils.handle_event/4,
      []
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Banchan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BanchanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
