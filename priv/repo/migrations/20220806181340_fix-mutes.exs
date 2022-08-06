defmodule :"Elixir.Banchan.Repo.Migrations.Fix-mutes" do
  use Ecto.Migration

  def change do
    execute(
      # Up
      fn ->
        repo().query!(
          """
          ALTER TABLE users DROP COLUMN muted_filter_query;
          """,
          [],
          log: false
        )

        repo().query!(
          """
          ALTER TABLE users ADD COLUMN muted_filter_query tsquery
            GENERATED ALWAYS AS (
              websearch_to_tsquery('banchan_fts', regexp_replace(muted, '\\s+', ' OR ', 'g'))
            ) STORED;
          """,
          [],
          log: false
        )
      end,
      # Down
      fn ->
        repo().query!(
          """
          ALTER TABLE users DROP COLUMN muted_filter_query;
          """,
          [],
          log: false
        )

        repo().query!(
          """
          ALTER TABLE users ADD COLUMN muted_filter_query tsquery
            GENERATED ALWAYS AS (
              websearch_to_tsquery('banchan_fts', muted)
            ) STORED;
          """,
          [],
          log: false
        )
      end
    )
  end
end
