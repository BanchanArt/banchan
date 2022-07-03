defmodule Banchan.Repo do
  use Ecto.Repo,
    otp_app: :banchan,
    adapter: Ecto.Adapters.Postgres

  use Scrivener

  def down_all do
    Ecto.Migrator.run(__MODULE__, Application.app_dir(:banchan, "priv/repo/migrations"), :down,
      all: true
    )
  end

  def up_all do
    Ecto.Migrator.run(__MODULE__, Application.app_dir(:banchan, "priv/repo/migrations"), :up,
      all: true
    )
  end
end
