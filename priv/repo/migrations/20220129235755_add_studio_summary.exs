defmodule Banchan.Repo.Migrations.AddStudioSummary do
  use Ecto.Migration

  def change do
    alter table(:studios) do
      add :summary, :text
    end
  end
end
