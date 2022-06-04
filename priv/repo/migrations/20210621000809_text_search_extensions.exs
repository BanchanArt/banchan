defmodule Banchan.Repo.Migrations.TextSearchExtensions do
  use Ecto.Migration

  def up do
    execute """
    CREATE EXTENSION unaccent;
    CREATE EXTENSION pg_trgm;
    """
  end

  def down do
    execute """
    DROP EXTENSION unaccent;
    DROP EXTENSION pg_trgm;
    """
  end
end
