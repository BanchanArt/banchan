defmodule Banchan.Repo.Migrations.AddDetailsToInvoices do
  use Ecto.Migration

  def change do
    alter table(:commission_invoices) do
      add :line_items, :map
      add :deposited, :money_with_currency
    end
  end
end
