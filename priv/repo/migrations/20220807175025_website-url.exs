defmodule Banchan.Repo.Migrations.WebsiteUrl do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :website_url, :text
    end
  end
end
