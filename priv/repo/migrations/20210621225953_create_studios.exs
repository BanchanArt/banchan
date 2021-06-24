defmodule Bespoke.Repo.Migrations.CreateStudios do
  use Ecto.Migration

  def change do
    create table(:studios, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :string
      add :header_img, :string
      add :pfp_img, :string
      add :card_img, :string

      add :user_id, references(:users, type: :binary_id), null: false
      timestamps()
    end
  end
end
