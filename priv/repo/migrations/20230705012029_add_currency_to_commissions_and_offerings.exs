defmodule Banchan.Repo.Migrations.AddCurrencyToCommissions do
  use Ecto.Migration

  def change do
    alter table(:commissions) do
      add :currency, :string
    end

    alter table(:offerings) do
      add :currency, :string
    end
  end
end
