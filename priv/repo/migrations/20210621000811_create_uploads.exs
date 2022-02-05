defmodule Banchan.Repo.Migrations.CreateUploads do
  use Ecto.Migration

  def change do
    create table(:uploads) do
      add :bucket, :string
      add :key, :string
      add :content_type, :string

      timestamps()
    end

    create unique_index(:uploads, [:bucket, :key])
  end
end
