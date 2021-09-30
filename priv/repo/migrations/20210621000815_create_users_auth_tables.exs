defmodule Banchan.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :roles, {:array, :string}, default: [], null: false
      add :name, :string
      add :bio, :string
      add :header_img, :string
      add :pfp_img, :string
      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:studios) do
      add :name, :string, null: false
      add :description, :string
      add :header_img, :string
      add :card_img, :string
      timestamps()
    end

    create table(:users_studios, primary_key: false) do
      add :user_id, references(:users), null: false
      add :studio_id, references(:studios), null: false
    end

    create table(:ats) do
      add :at, :citext, null: false
      add :user_id, references(:users)
      add :studio_id, references(:studios)

      timestamps()
    end

    create index(:ats, [:studio_id])
    create index(:ats, [:user_id])

  end
end
