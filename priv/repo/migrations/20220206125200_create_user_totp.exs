defmodule Banchan.Repo.Migrations.CreateUserTotp do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :totp_secret, :binary
      add :totp_activated, :boolean
    end
  end
end
