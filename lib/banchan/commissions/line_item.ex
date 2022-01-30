defmodule Banchan.Commissions.LineItem do
  @moduledoc """
  Main module for Commission line item data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "line_items" do
    field :amount, Money.Ecto.Composite.Type
    field :description, :string
    field :name, :string
    field :sticky, :boolean

    belongs_to :commission, Banchan.Commissions.Commission
    belongs_to :option, Banchan.Offerings.OfferingOption, foreign_key: :offering_option_id

    timestamps()
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:amount, :name, :description, :sticky])
    |> cast_assoc(:commission)
    |> cast_assoc(:option)
    |> validate_money(:amount)
    |> validate_required([:amount, :name, :description])
  end

  defp validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{} -> []
      _, _ -> [{field, "must be an amount"}]
    end)
  end
end
