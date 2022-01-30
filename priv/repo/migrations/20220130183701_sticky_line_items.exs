defmodule Banchan.Repo.Migrations.StickyLineItems do
  use Ecto.Migration

  def change do
    alter table(:line_items) do
      add :sticky, :boolean
    end
  end
end
