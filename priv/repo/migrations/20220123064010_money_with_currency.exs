defmodule Banchan.Repo.Migrations.MoneyWithCurrency do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE public.money_with_currency AS (amount integer, currency char(3))
    """
  end

  def down do
    execute """
    DROP TYPE public.money_with_currency
    """
  end
end
