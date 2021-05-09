defmodule ErotiCat.Users.User do
  @moduledoc """
  Represents all user types in ErotiCat.
  """
  use Ecto.Schema
  use Pow.Ecto.Schema

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword, PowEmailConfirmation]

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :roles, {:array, :string}, null: false, default: []
    field :username, :string, null: false, autogenerate: {__MODULE__, :auto_username, []}
    field :display_name, :string, null: false
    field :location, :string
    field :bio, :string

    pow_user_fields()
    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:roles, :display_name, :username])
    |> Ecto.Changeset.validate_required([:display_name])
    |> Ecto.Changeset.unique_constraint(:username)
    |> Ecto.Changeset.validate_subset(:roles, ~w(admin moderator creator))
  end

  def auto_username do
    "peep#{:rand.uniform(100_000_000)}"
  end
end
