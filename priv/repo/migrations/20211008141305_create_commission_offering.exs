defmodule Banchan.Repo.Migrations.CreateCommissionOffering do
  use Ecto.Migration

  def change do
    create table(:offerings) do
      add :name, :string
      add :summary, :string
      add :short_summary, :string
      add :open, :boolean, default: false, null: false
      add :price_range, :string

      add :studio, references(:studios), null: false
      timestamps()
    end

    alter table(:commissions) do
      remove :type,
      add :offering, references(:offerings), null: false
    end

    create index(:commissions, [:offering_id])
  end
end
