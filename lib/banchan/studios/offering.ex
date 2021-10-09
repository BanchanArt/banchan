defmodule Banchan.Studios.Offering do
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Studios.Studio

  schema "offerings" do
    field :type, :string
    field :name, :string
    field :open, :boolean, default: false
    field :price_range, :string
    field :short_summary, :string
    field :summary, :string

    belongs_to :studio, Studio

    timestamps()
  end

  @doc false
  def changeset(offering, attrs) do
    offering
    |> cast(attrs, [:name, :summary, :short_summary, :open, :price_range])
    |> validate_required([:name, :summary, :short_summary, :open, :price_range])
  end
end
