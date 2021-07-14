defmodule Banchan.MixProject do
  use Mix.Project

  def project do
    [
      app: :banchan,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      compilers: [:phoenix, :gettext, :surface] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        quality: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_ignore_apps: [:mnesia],
        ignore_warnings: ".dialyzer_ignores.exs"
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Banchan.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:pbkdf2_elixir, "~> 1.0"},
      {:phoenix, "~> 1.5.8"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:ecto_psql_extras, "~> 0.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.15.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:surface, "~> 0.5"},
      {:slugify, "~> 1.3.1"},
      {:bamboo, "~> 2.2.0"},
      # Testing and static analysis
      {:phx_gen_auth, "~> 0.7", only: [:dev], runtime: false},
      {:surface_formatter, "~> 0.5.1"},
      {:floki, ">= 0.27.0", only: :test},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.13", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      quality: [
        "compile --all-warnings --warnings-as-errors",
        "test",
        "format",
        "surface.format",
        "credo --strict",
        "sobelow --verbose",
        "dialyzer --ignore-exit-status"
      ],
      "quality.ci": [
        "compile --all-warnings --warnings-as-errors",
        "test --slowest 10",
        "format --check-formatted",
        "surface.format --check-formatted",
        "credo --strict",
        "sobelow --exit"
        # "dialyzer"
      ]
    ]
  end
end
