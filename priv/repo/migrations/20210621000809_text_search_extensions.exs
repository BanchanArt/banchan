defmodule Banchan.Repo.Migrations.TextSearchExtensions do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext;"

    execute """
    CREATE TEXT SEARCH CONFIGURATION banchan_fts ( COPY = english );
    """
  end

  def down do
    execute "DROP EXTENSION citext;"

    execute """
    DROP TEXT SEARCH CONFIGURATION banchan_fts;
    """
  end
end
