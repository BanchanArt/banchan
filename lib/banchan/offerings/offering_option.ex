defmodule Banchan.Offerings.OfferingOption do
  @moduledoc """
  Main module for OfferingOption data. These are the various options available for a offering.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Offerings.Offering

  schema "offering_options" do
    field :description, :string
    field :name, :string
    field :price, Money.Ecto.Composite.Type
    field :default, :boolean, default: false
    field :multiple, :boolean, default: false

    belongs_to :offering, Offering

    timestamps()
  end

  @doc false
  def changeset(offering_option, attrs) do
    offering_option
    |> cast(attrs, [:name, :description, :price, :default, :multiple])
    |> validate_money(:price)
    |> validate_required([:name, :description, :price])
    |> validate_length(:name, max: 50)
    |> validate_length(:description, max: 140)
  end
end
