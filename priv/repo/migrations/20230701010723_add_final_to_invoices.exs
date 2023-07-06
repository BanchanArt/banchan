defmodule Banchan.Repo.Migrations.AddFinalToInvoices do
  use Ecto.Migration

  def change do
    alter table(:commission_invoices) do
      add :final, :boolean, default: false, null: false
    end
  end
end
