defmodule Bespoke.Repo.Migrations.AddProfileInfo do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string, null: false
      add :display_name, :string, null: false
      add :location, :string
      add :bio, :string
    end

    create unique_index(:users, [:username])
  end
end
