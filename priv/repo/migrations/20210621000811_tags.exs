defmodule Banchan.Repo.Migrations.Tags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :tag, :citext, null: false
      add :count, :integer, null: false, default: 0
    end

    create unique_index(:tags, [:tag])

    execute(
      # Up
      fn ->
        repo().query(
          """
          CREATE OR REPLACE FUNCTION public.immutable_array_to_string(text[], text)
              RETURNS text as $$ SELECT array_to_string($1, $2); $$
          LANGUAGE sql IMMUTABLE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          CREATE OR REPLACE FUNCTION public.trigger_update_tags_count()
            RETURNS trigger
            LANGUAGE plpgsql
          AS $function$
          BEGIN
            IF TG_OP = 'DELETE' THEN
              INSERT INTO tags (tag, count)
                SELECT otag, 0
                FROM UNNEST(old.tags) otag
              ON CONFLICT (tag) DO UPDATE
                SET count = tags.count - 1;
              RETURN OLD;
            END IF;
            IF TG_OP = 'INSERT' THEN
              INSERT INTO tags (tag, count)
                SELECT ntag, 1
                FROM UNNEST(new.tags) ntag
              ON CONFLICT (tag) DO UPDATE
                SET count = tags.count + 1;
              RETURN NEW;
            END IF;
            IF TG_OP = 'UPDATE' THEN
              INSERT INTO tags (tag, count)
                SELECT COALESCE(ntag, otag),
                        (ntag IS NOT NULL)::int - (otag IS NOT NULL)::int
                FROM UNNEST(new.tags) ntag FULL JOIN
                      UNNEST(old.tags) otag
                      ON ntag = otag
              ON CONFLICT (tag) DO UPDATE
                SET count = tags.count + EXCLUDED.count;
              RETURN NEW;
            END IF;
          END;
          $function$;
          """,
          [],
          log: :info
        )
      end,

      # Down
      fn ->
        repo().query(
          """
          DROP FUNCTION IF EXISTS public.immutable_array_to_string();
          """,
          [],
          log: :info
        )

        repo().query(
          """
          DROP FUNCTION IF EXISTS public.trigger_update_tags_count();
          """,
          [],
          log: :info
        )
      end
    )
  end
end
