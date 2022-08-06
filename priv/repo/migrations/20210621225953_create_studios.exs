defmodule Banchan.Repo.Migrations.CreateStudios do
  use Ecto.Migration

  def change do
    create table(:studios) do
      add :name, :string, null: false
      add :handle, :citext, null: false
      add :about, :text
      add :country, :string, null: false
      add :tags, {:array, :citext}, default: [], null: false
      add :default_currency, :string, null: false
      add :payment_currencies, {:array, :string}, null: false
      add :featured, :boolean, default: false, null: false
      add :header_img_id, references(:uploads, on_delete: :nilify_all, type: :uuid)
      add :card_img_id, references(:uploads, on_delete: :nilify_all, type: :uuid)
      add :default_terms, :text
      add :default_template, :text
      add :stripe_id, :string
      add :stripe_charges_enabled, :boolean, default: false
      add :stripe_details_submitted, :boolean, default: false
      add :platform_fee, :decimal, null: false
      add :mature, :boolean, null: false
      timestamps()
    end

    execute(
      fn ->
        repo().query!(
          """
          ALTER TABLE studios ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (
              setweight(to_tsvector('banchan_fts', handle), 'A') ||
              setweight(to_tsvector('banchan_fts', name), 'B') ||
              setweight(to_tsvector('banchan_fts', immutable_array_to_string(tags, ' ')), 'C')
            ) STORED;
          """,
          [],
          log: false
        )

        repo().query!(
          """
          CREATE INDEX studios_search_idx ON studios USING GIN (search_vector);
          """,
          [],
          log: false
        )

        repo().query!(
          """
          CREATE INDEX studios_tags ON studios USING GIN (tags);
          """,
          [],
          log: false
        )

        repo().query!(
          """
          CREATE TRIGGER studios_tags_count_update
          AFTER UPDATE OR INSERT OR DELETE ON studios
          FOR EACH ROW
          EXECUTE PROCEDURE public.trigger_update_tags_count();
          """,
          [],
          log: false
        )
      end,
      fn ->
        repo().query!(
          """
          DROP INDEX studios_search_idx;
          """,
          [],
          log: false
        )

        repo().query!(
          """
          DROP INDEX studios_tags;
          """,
          [],
          log: false
        )
      end
    )

    create unique_index(:studios, [:handle])
    create unique_index(:studios, [:stripe_id])

    create table(:users_studios, primary_key: false) do
      add :user_id, references(:users), null: false
      add :studio_id, references(:studios), null: false

      # TODO: add these in.
      # timestamps()
    end

    create unique_index(:users_studios, [:user_id, :studio_id])

    create table(:studio_payouts) do
      add :public_id, :string, null: false
      add :stripe_payout_id, :string
      add :amount, :money_with_currency, null: false
      add :status, :string, null: false
      add :arrival_date, :naive_datetime
      add :method, :string
      add :type, :string
      add :failure_code, :string
      add :failure_message, :text
      add :actor_id, references(:users), null: false
      add :studio_id, references(:studios), null: false
      timestamps()
    end

    create unique_index(:studio_payouts, [:public_id])
    create unique_index(:studio_payouts, [:stripe_payout_id])
    create index(:studio_payouts, [:studio_id])

    create table(:studio_portfolio_images) do
      add :studio_id, references(:studios, on_delete: :delete_all), null: false
      add :upload_id, references(:uploads, on_delete: :delete_all, type: :uuid), null: false
      add :index, :integer, null: false

      timestamps()
    end

    create unique_index(:studio_portfolio_images, [:studio_id, :upload_id])
  end
end
