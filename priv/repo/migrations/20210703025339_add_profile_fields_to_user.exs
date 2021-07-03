defmodule Banchan.Repo.Migrations.AddProfileFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :bio, :string
      add :header_img, :string
      add :pfp_img, :string
    end
  end
end
