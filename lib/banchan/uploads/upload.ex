defmodule Banchan.Uploads.Upload do
  @moduledoc """
  Main module for upload data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User

  schema "uploads" do
    field :name, :string
    field :bucket, :string, null: false
    field :key, :string, null: false
    field :type, :string
    field :size, :integer, null: false

    belongs_to :uploader, User
    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:name, :key, :bucket, :type])
    |> validate_required([:key, :bucket])
    |> unique_constraint([:bucket, :key])
  end
end
