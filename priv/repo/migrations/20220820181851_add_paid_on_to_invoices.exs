defmodule Banchan.Repo.Migrations.AddPaidOnToInvoices do
  use Ecto.Migration

  def change do
    alter table(:commission_invoices) do
      add :paid_on, :utc_datetime
    end
  end
end
