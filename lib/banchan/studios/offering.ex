defmodule Banchan.Studios.Offering do
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Studios.Studio

  schema "offerings" do
    field :type, :string
    field :index, :integer
    field :name, :string
    field :description, :string
    field :open, :boolean, default: false
    field :price_range, :string

    belongs_to :studio, Studio

    timestamps()
  end

  @doc false
  def changeset(offering, attrs) do
    offering
    |> cast(attrs, [:type, :index, :name, :description, :open, :price_range])
    |> validate_required([:type, :index, :name, :description, :open])
    |> unique_constraint([:type, :studio_id])
  end
end
