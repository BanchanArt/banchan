defmodule Banchan.Repo.Migrations.CreateLineItems do
  use Ecto.Migration

  def change do
    create table(:line_items) do
      add :amount, :money_with_currency
      add :name, :string
      add :description, :text
      add :commission_id, references(:commissions, on_delete: :nothing)
      add :offering_option_id, references(:offering_options, on_delete: :nothing)

      timestamps()
    end

    create index(:line_items, [:commission_id])
    create index(:line_items, [:offering_option_id])
  end
end
