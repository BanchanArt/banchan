defmodule Banchan.Repo.Migrations.AddReports do
  use Ecto.Migration

  def change do
    create table(:reports, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :reporter_id, references(:users, on_delete: :nilify_all)
      add :investigator_id, references(:users, on_delete: :nilify_all)
      add :status, :string
      add :message, :text
      add :uri, :text, null: false
      add :notes, :text
      add :tags, {:array, :citext}, default: [], null: false

      timestamps()
    end

    create index(:reports, [:reporter_id])

    execute(
      fn ->
        repo().query!(
          """
          ALTER TABLE reports ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (
              setweight(to_tsvector('banchan_fts', coalesce(message, '')), 'A') ||
              setweight(to_tsvector('banchan_fts', coalesce(notes, '')), 'B') ||
              setweight(to_tsvector('banchan_fts', immutable_array_to_string(tags, ' ')), 'C')
            ) STORED;
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          CREATE INDEX reports_search_idx ON reports USING GIN (search_vector);
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          CREATE INDEX reports_tags ON reports USING GIN (tags);
          """,
          [],
          log: :info
        )
      end,
      fn ->
        repo().query!(
          """
          DROP INDEX studios_search_idx;
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          DROP INDEX studios_tags;
          """,
          [],
          log: :info
        )
      end
    )
  end
end
