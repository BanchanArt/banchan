defmodule Banchan.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "studios" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :header_img, :string
    field :card_img, :string

    many_to_many :artists, Banchan.Accounts.User, join_through: "users_studios"

    has_many :offerings, Banchan.Studios.Offering

    timestamps()
  end

  @doc false
  def changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
  end
end
