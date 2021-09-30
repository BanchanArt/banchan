defmodule Banchan.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User
  alias Banchan.Ats.At

  schema "studios" do
    field :name, :string
    field :description, :string
    field :header_img, :string
    field :card_img, :string

    has_one :at, At
    many_to_many :artists, User, join_through: "users_studios"

    timestamps()
  end

  @doc false
  def changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> cast_assoc(:at, with: &At.changeset/2)
  end
end
