defmodule Banchan.Repo.Migrations.AddForex do
  use Ecto.Migration

  def change do
    create table(:foreign_exchange_rates) do
      add :from, :string, null: false
      add :to, :string, null: false
      add :rate, :float, null: false
      timestamps()
    end

    create unique_index(:foreign_exchange_rates, [:from, :to])
  end
end
