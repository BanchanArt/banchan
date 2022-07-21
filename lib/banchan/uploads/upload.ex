defmodule Banchan.Uploads.Upload do
  @moduledoc """
  Main module for upload data.
  """
  use Ecto.Schema
  use Ecto.Type
  import Ecto.Changeset

  alias Banchan.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "uploads" do
    field :name, :string
    field :bucket, :string
    field :key, :string
    field :type, :string
    field :size, :integer
    field :pending, :boolean, default: true

    belongs_to :uploader, User
    belongs_to :original, __MODULE__, on_replace: :nilify, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:name, :key, :bucket, :type, :size, :pending])
    |> validate_required([:key, :bucket])
    |> unique_constraint([:bucket, :key])
  end

  def update_changeset(upload, attrs) do
    upload
    |> cast(attrs, [:name, :type, :size, :pending])
  end

  def type, do: :map

  def cast(%__MODULE__{} = upload), do: {:ok, upload}
  def cast(_), do: :error

  def load(data) when is_map(data) do
    data =
      for {key, val} <- data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct!(__MODULE__, data)}
  end

  def dump(%__MODULE__{} = upload), do: {:ok, Map.from_struct(upload)}
  def dump(_), do: :error
end
