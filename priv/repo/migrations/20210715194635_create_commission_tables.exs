defmodule Banchan.Repo.Migrations.CreateCommissionOffering do
  use Ecto.Migration

  def change do
    create table(:offerings) do
      add :type, :citext, null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :base_price, :money_with_currency
      add :open, :boolean, default: false, null: false
      add :index, :integer
      add :terms, :text

      add :studio_id, references(:studios), null: false

      timestamps()
    end

    create unique_index(:offerings, [:type, :studio_id])

    create table(:commissions) do
      add :public_id, :string, null: false
      add :title, :string
      add :description, :text
      add :status, :string
      add :studio_id, references(:studios, on_delete: :nothing)
      add :client_id, references(:users, on_delete: :nothing)
      add :offering_id, references(:offerings), null: false

      timestamps()
    end

    create index(:commissions, [:offering_id])
    create index(:commissions, [:studio_id])
    create index(:commissions, [:client_id])
    create unique_index(:commissions, [:public_id, :studio_id])

    create table(:commission_events) do
      add :type, :citext, null: false
      add :text, :text
      add :amount, :money_with_currency
      add :status, :string

      add :commission_id, references(:commissions, on_delete: :delete_all), null: false
      add :actor_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:commission_events, [:commission_id])
    create index(:commission_events, [:actor_id])

    create table(:offering_options) do
      add :name, :string
      add :description, :text
      add :price, :money_with_currency
      add :offering_id, references(:offerings, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:offering_options, [:offering_id])

    create table(:line_items) do
      add :amount, :money_with_currency
      add :name, :string
      add :description, :text
      add :commission_id, references(:commissions, on_delete: :nothing)
      add :offering_option_id, references(:offering_options, on_delete: :nothing)
      add :sticky, :boolean

      timestamps()
    end

    create index(:line_items, [:commission_id])
    create index(:line_items, [:offering_option_id])
  end
end
