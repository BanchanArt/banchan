defmodule Banchan.Uploads.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "s3_uploads" do
    field :bucket, :string
    field :key, :string
    field :content_type, :string

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:key, :bucket, :content_type])
    |> validate_required([:key, :bucket, :content_type])
    |> unique_constraint([:bucket, :key])
  end
end
