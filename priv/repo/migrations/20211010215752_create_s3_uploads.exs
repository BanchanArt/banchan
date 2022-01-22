defmodule Banchan.Repo.Migrations.CreateS3Uploads do
  use Ecto.Migration

  def change do
    create table(:s3_uploads) do
      add :bucket, :string
      add :key, :string
      add :content_type, :string

      timestamps()
    end

    create unique_index(:s3_uploads, [:bucket, :key])
  end
end
