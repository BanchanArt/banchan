defmodule Banchan.Repo.Migrations.CreateCommissions do
  use Ecto.Migration

  def change do
    create table(:commissions) do
      add :title, :string
      add :open, :boolean
      add :studio_id, references(:studios, on_delete: :nothing)
      add :client_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:commissions, [:studio_id])
    create index(:commissions, [:client_id])
  end
end
