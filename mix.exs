defmodule Banchan.MixProject do
  use Mix.Project

  def project do
    [
      app: :banchan,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      compilers: [:phoenix, :gettext] ++ Mix.compilers() ++ [:surface],
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
      extra_applications: [:logger, :runtime_tools, :os_mon, :crypto]
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
      {:phoenix, "~> 1.6.8"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.8.3"},
      {:ecto_psql_extras, "~> 0.7.4"},
      {:postgrex, "~> 0.16.3"},
      {:phoenix_html, "~> 3.2.0"},
      {:phoenix_live_view, "~> 0.17.9"},
      {:phoenix_live_dashboard, "~> 0.6.5"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.5.2"},
      {:money, "~> 1.9"},
      {:surface, "~> 0.7.4"},
      {:slugify, "~> 1.3.1"},
      {:number, "~> 1.0.3"},
      {:bamboo, "~> 2.2.0"},
      {:ex_aws, "~> 2.3.1"},
      {:ex_aws_s3, "~> 2.3.2"},
      {:hackney, "~> 1.18"},
      {:sweet_xml, "~> 0.6"},
      {:earmark, "~> 1.4.20"},
      {:html_sanitize_ex, "~> 1.4.2"},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.7.6"},
      {:mogrify, "~> 0.9.1"},
      {:scrivener_ecto, "~> 2.7.0"},
      {:nimble_totp, "~> 0.1.0"},
      {:qr_code, "~> 2.2.1"},
      {:stripity_stripe, "~> 2.15.0"},
      {:ueberauth, "~> 0.7"},
      {:ueberauth_discord, "~> 0.7.0"},
      {:ueberauth_twitter, "~> 0.4.1"},
      {:ueberauth_google, "~> 0.10.1"},
      {:phoenix_live_reload, "~> 1.3.3", only: :dev},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      # Testing and static analysis
      {:mox, "~> 1.0.1", only: :test},
      {:surface_formatter, "~> 0.7.5", only: :dev},
      {:floki, ">= 0.27.0", only: :test},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runime: false},
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
      "stripe.local": [
        "cmd stripe listen --forward-to localhost:4000/api/stripe_webhook"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.deploy": [
        "cmd --cd assets npm install",
        "cmd --cd assets npm run deploy:css",
        "esbuild default --minify",
        "phx.digest"
      ],
      reset: [
        "deps.get",
        "cmd --cd assets npm install",
        "ecto.reset"
      ],
      fmt: ["format"],
      test: ["ecto.reset --quiet", "test"],
      quality: [
        "compile --all-warnings --warnings-as-errors",
        "test",
        "format",
        "credo --strict",
        "sobelow --verbose",
        "dialyzer --ignore-exit-status"
      ],
      "quality.ci": [
        "compile --all-warnings --warnings-as-errors",
        "test --slowest 10",
        "format --check-formatted",
        "credo --strict",
        "sobelow --exit"
        # "dialyzer"
      ]
    ]
  end
end
