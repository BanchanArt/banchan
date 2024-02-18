defmodule Banchan.Repo.Migrations.CreateWorks do
  use Ecto.Migration

  def change do
    create table(:works) do
      add :public_id, :string, null: false
      add :title, :string, null: false
      add :description, :text, null: false
      add :tags, {:array, :string}, null: false
      add :private, :boolean, default: false, null: false
      add :mature, :boolean, default: false, null: false
      add :studio_id, references(:studios, on_delete: :delete_all), null: false
      add :client_id, references(:users, on_delete: :nilify_all)
      add :offering_id, references(:offerings, on_delete: :nilify_all)
      add :commission_id, references(:commissions, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:works, [:studio_id, :public_id])
    create index(:works, [:client_id])
    create index(:works, [:offering_id])
    create index(:works, [:commission_id])

    execute(
      fn ->
        repo().query!(
          """
          ALTER TABLE works ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (
              setweight(to_tsvector('banchan_fts', title), 'A') ||
              setweight(to_tsvector('banchan_fts', description), 'B') ||
              setweight(to_tsvector('banchan_fts', immutable_array_to_string(tags, ' ')), 'C')
            ) STORED;
          """,
          [],
          log: false
        )

        repo().query!(
          """
          CREATE INDEX works_search_idx ON works USING GIN (search_vector);
          """,
          [],
          log: false
        )

        repo().query!(
          """
          CREATE INDEX works_tags ON works USING GIN (tags);
          """,
          [],
          log: false
        )

        repo().query!(
          """
          CREATE TRIGGER works_tags_count_update
          AFTER UPDATE OR INSERT OR DELETE ON works
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
          DROP INDEX works_search_idx;
          """,
          [],
          log: false
        )

        repo().query!(
          """
          DROP INDEX works_tags;
          """,
          [],
          log: false
        )
      end
    )

    create table(:work_uploads) do
      add :comment, :text
      add :work_id, references(:works, on_delete: :delete_all), null: false
      add :upload_id, references(:uploads, on_delete: :delete_all, type: :uuid), null: false
      add :preview_id, references(:uploads, on_delete: :nilify_all, type: :uuid)
      add :index, :integer, null: false

      timestamps()
    end

    create index(:work_uploads, [:work_id])
    create index(:work_uploads, [:upload_id])
    create index(:work_uploads, [:work_id, :upload_id])
    create index(:work_uploads, [:preview_id])
    create unique_index(:work_uploads, [:work_id, :index])
  end
end
