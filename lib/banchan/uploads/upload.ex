defmodule Banchan.Uploads.Upload do
  @moduledoc """
  Main module for upload data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "uploads" do
    field :name, :string
    field :bucket, :string
    field :key, :string
    field :content_type, :string

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:name, :key, :bucket, :content_type])
    |> validate_required([:name, :key, :bucket, :content_type])
    |> unique_constraint([:bucket, :key])
  end
end
