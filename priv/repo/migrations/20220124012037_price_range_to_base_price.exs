defmodule Banchan.Repo.Migrations.PriceRangeToBasePrice do
  use Ecto.Migration

  def change do
    alter table(:offerings) do
      remove :price_range
      add :base_price, :money_with_currency
    end
  end
end
