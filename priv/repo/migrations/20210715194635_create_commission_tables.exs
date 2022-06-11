defmodule Banchan.Repo.Migrations.CreateCommissionOffering do
  use Ecto.Migration

  def change do
    create table(:offerings) do
      add :type, :citext, null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :open, :boolean, default: false, null: false
      add :hidden, :boolean, default: true, null: false
      add :slots, :integer
      add :max_proposals, :integer
      add :index, :integer
      add :terms, :text
      add :template, :text

      add :studio_id, references(:studios), null: false

      timestamps()
    end

    create unique_index(:offerings, [:type, :studio_id])

    create table(:offering_options) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :price, :money_with_currency, null: false
      add :offering_id, references(:offerings, on_delete: :delete_all), null: false
      add :default, :boolean, default: false, null: false
      add :sticky, :boolean, default: false, null: false
      add :multiple, :boolean, default: false, null: false

      timestamps()
    end

    create index(:offering_options, [:offering_id])

    create table(:commissions) do
      add :public_id, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :status, :string, null: false
      add :studio_id, references(:studios, on_delete: :nilify_all)
      add :client_id, references(:users, on_delete: :nilify_all)
      add :offering_id, references(:offerings, on_delete: :nilify_all)

      timestamps()
    end

    execute(
      fn ->
        repo().query!(
          """
          ALTER TABLE commissions ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (
              setweight(to_tsvector('banchan_fts', title), 'A') ||
              setweight(to_tsvector('banchan_fts', coalesce(description, '')), 'B')
            ) STORED;
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          CREATE INDEX commissions_search_idx ON commissions USING GIN (search_vector);
          """,
          [],
          log: :info
        )
      end,
      fn ->
        repo().query!(
          """
          DROP INDEX commissions_search_idx;
          """,
          [],
          log: :info
        )
      end
    )

    create index(:commissions, [:offering_id])
    create index(:commissions, [:studio_id])
    create index(:commissions, [:client_id])
    create unique_index(:commissions, [:public_id, :studio_id])

    create table(:commission_archived) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :commission_id, references(:commissions, on_delete: :delete_all)
      add :archived, :boolean, null: false

      timestamps()
    end

    create unique_index(:commission_archived, [:user_id, :commission_id])

    create table(:commission_events) do
      add :public_id, :string, null: false
      add :type, :citext, null: false
      add :text, :text
      add :amount, :money_with_currency
      add :status, :string

      add :commission_id, references(:commissions, on_delete: :delete_all), null: false
      add :actor_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    execute(
      fn ->
        repo().query!(
          """
          ALTER TABLE commission_events ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (to_tsvector('banchan_fts', coalesce(text, ''))) STORED;
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          CREATE INDEX commission_events_search_idx ON commission_events USING GIN (search_vector);
          """,
          [],
          log: :info
        )
      end,
      fn ->
        repo().query!(
          """
          DROP INDEX commission_events_search_idx;
          """,
          [],
          log: :info
        )
      end
    )

    create index(:commission_events, [:commission_id])
    create index(:commission_events, [:actor_id])

    create table(:line_items) do
      add :amount, :money_with_currency, null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :commission_id, references(:commissions, on_delete: :delete_all), null: false
      add :offering_option_id, references(:offering_options, on_delete: :nilify_all)
      add :sticky, :boolean

      timestamps()
    end

    create index(:line_items, [:commission_id])
    create index(:line_items, [:offering_option_id])

    create table(:event_attachments) do
      add :event_id, references(:commission_events, on_delete: :delete_all)
      add :upload_id, references(:uploads, on_delete: :delete_all, type: :uuid)
      add :thumbnail_id, references(:uploads, on_delete: :nilify_all, type: :uuid)

      timestamps()
    end

    create index(:event_attachments, [:event_id])
    create index(:event_attachments, [:upload_id])

    create table(:commission_invoices) do
      add :checkout_url, :text
      add :stripe_session_id, :string
      add :stripe_refund_id, :string
      add :refund_status, :string
      add :status, :string, null: false
      add :tip, :money_with_currency
      add :amount, :money_with_currency, null: false
      add :platform_fee, :money_with_currency
      add :required, :boolean, default: false
      add :commission_id, references(:commissions, on_delete: :nothing)
      add :client_id, references(:users, on_delete: :nothing)
      add :event_id, references(:commission_events, on_delete: :nothing)
      add :payout_available_on, :utc_datetime

      timestamps()
    end

    create unique_index(:commission_invoices, [:stripe_session_id])
    create unique_index(:commission_invoices, [:stripe_refund_id])
    create index(:commission_invoices, [:commission_id])
    create index(:commission_invoices, [:client_id])
    create index(:commission_invoices, [:event_id])

    create table(:invoices_payouts) do
      add :invoice_id, references(:commission_invoices), null: false
      add :payout_id, references(:studio_payouts), null: false
    end

    create unique_index(:invoices_payouts, [:invoice_id, :payout_id])
  end
end
