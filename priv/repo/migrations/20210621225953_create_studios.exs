defmodule Banchan.Repo.Migrations.CreateStudios do
  use Ecto.Migration

  def change do
    create table(:studios) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :string
      add :header_img, :string
      add :card_img, :string
      timestamps()
    end

    create table(:users_studios, primary_key: false) do
      add :user_id, references(:users), null: false
      add :studio_id, references(:studios), null: false
    end
  end
end
