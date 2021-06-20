defmodule Bespoke.Repo.Migrations.AddRoles do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :roles, {:array, :string}, null: false, default: []
    end
  end
end
