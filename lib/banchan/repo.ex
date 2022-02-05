defmodule Banchan.Repo do
  use Ecto.Repo,
    otp_app: :banchan,
    adapter: Ecto.Adapters.Postgres

  use Scrivener
end
