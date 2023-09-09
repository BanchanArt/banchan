defmodule Banchan.MixProject do
  use Mix.Project

  def project do
    [
      app: :banchan,
      version: "1.3.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      compilers: Mix.compilers() ++ [:surface],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        quality: :test,
        "quality.ci": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
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
  defp elixirc_paths(:test), do: ["lib", "test/support"] ++ catalogues()
  defp elixirc_paths(:dev), do: ["lib"] ++ catalogues()
  defp elixirc_paths(_), do: ["lib"]

  def catalogues do
    [
      "priv/catalogue"
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 2.3.0"},
      {:bamboo_phoenix, "~> 1.0.0"},
      {:csv, "~> 3.0.5"},
      {:earmark, "~> 1.4.32"},
      {:ecto_psql_extras, "~> 0.7.11"},
      {:ecto_sql, "~> 3.10.1"},
      {:eqrcode, "~> 0.1.10"},
      {:ex_aws, "~> 2.4.2"},
      {:ex_aws_s3, "~> 2.4.0"},
      {:ffmpex, "~> 0.10.0"},
      {:gettext, "~> 0.22.2"},
      {:hackney, "~> 1.18.1"},
      {:html_sanitize_ex, "~> 1.4.2"},
      # TODO: Can't bump this one to ~>2 because of tentacat
      {:httpoison, "~> 1.8.1"},
      {:jason, "~> 1.4.0"},
      {:libcluster, "~> 3.3"},
      {:makeup_elixir, ">= 0.0.0"},
      {:makeup_erlang, ">= 0.0.0"},
      {:mogrify, "~> 0.9.3"},
      {:money, "~> 1.12.2"},
      {:nimble_publisher, "~> 1.0.0"},
      {:nimble_totp, "~> 1.0.0"},
      {:number, "~> 1.0.4"},
      {:oban, "~> 2.15.1"},
      {:pbkdf2_elixir, "~> 2.1.0"},
      {:phoenix, "~> 1.7.6"},
      {:phoenix_ecto, "~> 4.4.2"},
      {:phoenix_html, "~> 3.3.1"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      # TODO: We have to keep a patched LiveView do to unmerged/unreleased fixes:
      # * https://github.com/phoenixframework/phoenix_live_view/commit/7daaf5ccb5a631f448eea5f8538508feb175c6f5
      # * https://github.com/phoenixframework/phoenix_live_view/pull/2528
      {:phoenix_live_view,
       github: "BanchanArt/phoenix_live_view",
       ref: "e9d31749431f28867fc16262dac5fc9c1df5558a",
       override: true},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.6.1"},
      {:postgrex, "~> 0.17.1"},
      {:prime, "~> 0.1.1"},
      {:scrivener_ecto, "~> 2.7.0"},
      {:sentry, "~> 8.0.6"},
      {:slugify, "~> 1.3.1"},
      # TODO: remove this line when the package gets fixed. See https://github.com/elixir-lang/elixir/issues/12681#issuecomment-1598312912
      {:ssl_verify_fun, "~> 1.1.7", manager: :rebar3, override: true},
      {:stripity_stripe, "~> 2.17.3"},
      {:surface, "~> 0.11.0"},
      {:surface_catalogue, "~> 0.6.1"},
      {:surface_markdown, "~> 0.6.1"},
      {:sweet_xml, "~> 0.7.3"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0.0"},
      {:tentacat, "~> 2.2.0"},
      {:timex, "~> 3.7.11"},
      {:ueberauth_discord, "~> 0.7.0"},
      {:ueberauth_google, "~> 0.10.2"},
      {:ueberauth, "~> 0.10.5"},
      {:uuid, "~> 1.1.8"},

      # Dev/test deps
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3.0", only: [:dev, :test], runtime: false},
      {:esbuild, "~> 0.7.0", runtime: Mix.env() == :dev},
      {:excoveralls, "~> 0.16.1", only: :test},
      {:floki, "~> 0.34.3", only: :test},
      {:git_cli, "~> 0.3.0", only: :dev},
      {:mox, "~> 1.0.2", only: :test},
      {:phoenix_live_reload, "~> 1.4.1", only: :dev},
      {:sobelow, "~> 0.12.2", only: [:dev, :test], runtime: false},
      {:surface_formatter, "~> 0.7.5", only: :dev},
      {:versioce, "~> 2.0.0", only: [:dev, :test]}
      | if System.get_env("MIX_ENV") == "prod" do
          [{:oban_web, "~> 2.10.0-rc.1", repo: "oban", only: :prod}]
        else
          []
        end
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
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "deploy.dev": [fn _ -> deploy("dev.banchan.art", "dev") end],
      "deploy.prod": [fn _ -> deploy("banchan.art", "prod") end],
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
      test: [
        "ecto.drop --quiet",
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/seeds.exs",
        "test"
      ],
      quality: [
        "compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "test"
        # ,
        # Need to fix some stuff and it's pretty noisy. Disabling for now.
        # "sobelow --verbose"
        # ,
        # "dialyzer --ignore-exit-status"
      ],
      # Tag a new release.
      bump: ["bump", "cmd git push --follow-tags"]
    ]
  end

  def deploy(host, env) do
    Mix.Task.run("app.config")

    Mix.Shell.IO.cmd(
      "flyctl deploy -a banchan-#{env} --build-arg BANCHAN_HOST=#{host} --build-arg BANCHAN_DEPLOY_ENV=#{env} --build-secret OBAN_KEY_FINGERPRINT=#{Application.get_env(:banchan, :oban_key_fingerprint)} --build-secret OBAN_LICENSE_KEY=#{Application.get_env(:banchan, :oban_license_key)}"
    )
  end
end
