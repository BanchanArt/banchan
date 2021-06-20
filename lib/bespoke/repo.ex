defmodule Bespoke.Repo do
  use Ecto.Repo,
    otp_app: :bespoke,
    adapter: Ecto.Adapters.Postgres
end
