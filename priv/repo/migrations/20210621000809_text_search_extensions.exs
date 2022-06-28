defmodule Banchan.Repo.Migrations.TextSearchExtensions do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext;"

    # TODO: enable these and set stuff up again once we're ready for a paid
    # gigalixir tier. This isn't supported on the free tier. :(

    # execute """
    # CREATE EXTENSION unaccent;
    # """

    # execute """
    # CREATE EXTENSION pg_trgm;
    # """

    execute """
    CREATE TEXT SEARCH CONFIGURATION banchan_fts ( COPY = english );
    """

    # execute """
    # ALTER TEXT SEARCH CONFIGURATION banchan_fts
    #   ALTER MAPPING FOR hword, hword_part, word
    #   WITH unaccent, simple;
    # """
  end

  def down do
    execute "DROP EXTENSION citext;"

    # execute """
    # DROP EXTENSION unaccent;
    # """

    # execute """
    # DROP EXTENSION pg_trgm;
    # """

    execute """
    DROP TEXT SEARCH CONFIGURATION banchan_fts;
    """
  end
end
