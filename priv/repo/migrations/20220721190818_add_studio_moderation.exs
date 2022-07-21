defmodule Banchan.Repo.Migrations.AddStudioModeration do
  use Ecto.Migration

  def change do
    alter table(:studios) do
      add :moderation_notes, :text
    end

    create table(:studio_disable_history) do
      add :studio_id, references(:studios, on_delete: :delete_all), null: false
      add :disabled_by_id, references(:users, on_delete: :delete_all)
      add :disabled_at, :naive_datetime
      add :disabled_until, :naive_datetime
      add :disabled_reason, :text
      add :lifted_by_id, references(:users, on_delete: :delete_all)
      add :lifted_reason, :text
      add :lifted_at, :naive_datetime
    end

    create index(:studio_disable_history, [:studio_id])
  end
end
