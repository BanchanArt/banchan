defmodule Banchan.Repo.Migrations.CreateS3Uploads do
  use Ecto.Migration

  def change do
    create table(:s3_uploads) do
      add :key, :string
      add :bucket, :string

      timestamps()
    end

    create unique_index(:s3_uploads, [:bucket, :key])
  end
end
