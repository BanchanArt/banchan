defmodule Banchan.Repo.Migrations.CreateCommissionOffering do
  use Ecto.Migration

  def change do
    create table(:offerings) do
      add :type, :string, null: false
      add :name, :string, null: false
      add :description, :string, null: false
      add :open, :boolean, default: false, null: false
      add :price_range, :string
      add :index, :integer, null: false

      add :studio_id, references(:studios), null: false

      timestamps()
    end

    create unique_index(:offerings, [:type, :studio_id])

    alter table(:commissions) do
      add :offering_id, references(:offerings), null: false
    end

    create index(:commissions, [:offering_id])
  end
end
