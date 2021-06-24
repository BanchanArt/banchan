defmodule Bespoke.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "studios" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :header_img, :string
    field :pfp_img, :string
    field :card_img, :string

    belongs_to :user, Bespoke.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
  end
end
