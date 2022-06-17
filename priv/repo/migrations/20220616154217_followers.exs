defmodule Banchan.Repo.Migrations.Followers do
  use Ecto.Migration

  def change do
    create table(:user_followers) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :target_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:user_followers, [:user_id, :target_id])
    create index(:user_followers, [:target_id])

    create table(:studio_followers) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :studio_id, references(:studios, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:studio_followers, [:user_id, :studio_id])
    create index(:studio_followers, [:studio_id])
  end
end
