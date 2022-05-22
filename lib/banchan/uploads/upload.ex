defmodule Banchan.Uploads.Upload do
  @moduledoc """
  Main module for upload data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "uploads" do
    field :name, :string
    field :bucket, :string
    field :key, :string
    field :type, :string
    field :size, :integer

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
