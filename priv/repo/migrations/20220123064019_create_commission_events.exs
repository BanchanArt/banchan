defmodule Banchan.Repo.Migrations.CreateCommissionEvents do
  use Ecto.Migration

  def change do
    create table(:commission_events) do
      add :type, :string, null: false
      add :text, :string
      add :amount, :money_with_currency
      add :status, :string

      add :commission_id, references(:commissions, on_delete: :delete_all), null: false
      add :actor_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:commission_events, [:commission_id])
    create index(:commission_events, [:actor_id])
  end
end
