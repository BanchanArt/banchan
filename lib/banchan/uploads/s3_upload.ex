defmodule Banchan.Uploads.S3Upload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "s3_uploads" do
    field :bucket, :string
    field :path, :string
    field :key, :string

    timestamps()
  end

  @doc false
  def changeset(s3_upload, attrs) do
    s3_upload
    |> cast(attrs, [:key, :bucket])
    |> validate_required([:key, :bucket])
    |> unique_constraint([:bucket, :key])
  end
end
