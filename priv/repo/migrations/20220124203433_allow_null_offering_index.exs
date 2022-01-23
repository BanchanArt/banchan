defmodule Banchan.Repo.Migrations.AllowNullOfferingIndex do
  use Ecto.Migration

  def change do
    alter table(:offerings) do
      modify :index, :integer, null: true
    end
  end
end
