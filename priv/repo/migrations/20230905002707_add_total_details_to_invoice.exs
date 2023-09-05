defmodule Banchan.Repo.Migrations.AddTaxToInvoice do
  use Ecto.Migration

  def change do
    alter table(:commission_invoices) do
      add :tax, :money_with_currency
      add :discounts, :money_with_currency
      add :shipping, :money_with_currency
    end
  end
end
