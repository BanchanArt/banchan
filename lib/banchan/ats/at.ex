defmodule Banchan.Ats.At do
  @moduledoc """
  Handles ("@s") for users and studios, which share a handle namespace.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "ats" do
    field :at, :string

    belongs_to :user, Banchan.Accounts.User
    belongs_to :studio, Banchan.Studios.Studio
    timestamps()
  end

  @doc false
  def changeset(at, attrs) do
    at
    |> cast(attrs, [:at])
    |> validate_required([:at])
    |> unique_constraint(:at)
    |> validate_at()
  end

  defp validate_at(changeset) do
    changeset
    |> validate_required([:at])
    |> validate_format(:at, ~r/^[a-zA-Z0-9_]+$/,
      message: "only letters, numbers, and underscores allowed"
    )
    |> validate_length(:at, min: 3, max: 16)
    |> unsafe_validate_unique(:at, Banchan.Repo)
    |> unique_constraint(:at)
  end
end
