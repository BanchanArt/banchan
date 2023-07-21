defmodule Banchan.Commissions.LineItem do
  @moduledoc """
  Main module for Commission line item data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  schema "line_items" do
    field :amount, Money.Ecto.Composite.Type
    field :description, :string
    field :name, :string
    field :sticky, :boolean
    field :multiple, :boolean, default: false
    field :count, :integer, default: 1

    belongs_to :commission, Banchan.Commissions.Commission
    belongs_to :option, Banchan.Offerings.OfferingOption, foreign_key: :offering_option_id

    timestamps()
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:amount, :name, :description, :sticky, :count, :multiple])
    |> cast_assoc(:commission)
    |> cast_assoc(:option)
    |> validate_number(:count, greater_than_or_equal_to: 1)
    |> validate_money(:amount)
    |> validate_required([:amount, :name, :description])
    |> validate_length(:name, max: 50)
    |> validate_length(:description, max: 160)
  end

  @doc false
  def custom_changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:amount, :name, :description])
    |> validate_money(:amount)
    |> validate_required([:amount, :name, :description])
    |> validate_length(:name, max: 50)
    |> validate_length(:description, max: 160)
  end

  @doc false
  def count_changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:count])
    |> validate_required(:count)
    |> validate_number(:count, greater_than_or_equal_to: 0)
  end
end
