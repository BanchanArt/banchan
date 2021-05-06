defmodule ErotiCat.Repo do
  use Ecto.Repo,
    otp_app: :eroticat,
    adapter: Ecto.Adapters.Postgres
end
