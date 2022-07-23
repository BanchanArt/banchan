defmodule Banchan.Repo.Migrations.AddStudioBlocklist do
  use Ecto.Migration

  def change do
    create table(:studio_block) do
      add :studio_id, references(:studios, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)
      add :reason, :text

      timestamps()
    end

    create unique_index(:studio_block, [:studio_id, :user_id])
    create index(:studio_block, [:user_id])
    create index(:studio_block, [:studio_id])
  end
end
