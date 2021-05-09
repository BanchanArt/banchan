defmodule ErotiCat.Users.User do
  @moduledoc """
  Represents all user types in ErotiCat.
  """
  use Ecto.Schema
  use Pow.Ecto.Schema

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword, PowEmailConfirmation]

  schema "users" do
    field :roles, {:array, :string}, null: false, default: []

    pow_user_fields()
    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:roles])
    |> Ecto.Changeset.validate_subset(:roles, ~w(admin model))
  end
end
