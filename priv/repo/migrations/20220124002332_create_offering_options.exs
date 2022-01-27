defmodule Banchan.Repo.Migrations.CreateOfferingOptions do
  use Ecto.Migration

  def change do
    create table(:offering_options) do
      add :name, :string
      add :description, :string
      add :price, :money_with_currency
      add :offering_id, references(:offerings, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:offering_options, [:offering_id])
  end
end
