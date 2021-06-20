defmodule Bespoke.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :email, :string, null: false
      add :password_hash, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
