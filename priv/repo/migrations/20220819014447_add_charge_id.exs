defmodule Banchan.Repo.Migrations.AddBalanceTransactionId do
  use Ecto.Migration

  def change do
    alter table(:commission_invoices) do
      add :stripe_charge_id, :string
    end
  end
end
