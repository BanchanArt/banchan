defmodule Banchan.Repo.Migrations.AddUnaccent do
  use Ecto.Migration

  def up do
    execute """
    CREATE EXTENSION unaccent;
    """

    execute """
    ALTER TEXT SEARCH CONFIGURATION banchan_fts
      ALTER MAPPING FOR hword, hword_part, word
      WITH unaccent, simple;
    """
  end

  def down do
    execute """
    DROP EXTENSION unaccent;
    """
  end
end
