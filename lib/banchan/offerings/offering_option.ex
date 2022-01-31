defmodule Banchan.Offerings.OfferingOption do
  @moduledoc """
  Main module for OfferingOption data. These are the various options available for a offering.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Offerings.Offering

  schema "offering_options" do
    field :description, :string
    field :name, :string
    field :price, Money.Ecto.Composite.Type
    field :default, :boolean, default: false
    field :sticky, :boolean, default: false

    belongs_to :offering, Offering

    timestamps()
  end

  @doc false
  def changeset(offering_option, attrs) do
    offering_option
    |> cast(attrs, [:name, :description, :price, :default, :sticky])
    |> validate_money(:price)
    |> validate_required([:name, :description, :price])
  end

  defp validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 -> []
      _, _ -> [{field, "can't be negative"}]
    end)
  end
end
