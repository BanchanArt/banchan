defmodule Banchan.Commissions.Offering do
  use Ecto.Schema
  import Ecto.Changeset

  schema "commission_offering" do
    field :name, :string
    field :open, :boolean, default: false
    field :price_range, :string
    field :short_summary, :string
    field :summary, :string

    timestamps()
  end

  @doc false
  def changeset(offering, attrs) do
    offering
    |> cast(attrs, [:name, :summary, :short_summary, :open, :price_range])
    |> validate_required([:name, :summary, :short_summary, :open, :price_range])
  end
end
