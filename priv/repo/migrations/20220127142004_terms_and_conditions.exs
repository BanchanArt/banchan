defmodule Banchan.Repo.Migrations.TermsAndConditions do
  use Ecto.Migration

  def change do
    alter table(:offerings) do
      add :terms, :text
    end
  end
end
