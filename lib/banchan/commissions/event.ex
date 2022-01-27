defmodule Banchan.Commissions.Event do
  @moduledoc """
  Main module for Commission Event data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "commission_events" do
    field :type, Ecto.Enum, values: [:comment, :line_item, :payment_request, :status, :attachment]
    field :text, :string
    field :amount, Money.Ecto.Composite.Type
    field :status, Ecto.Enum,
      values: Banchan.Commissions.Commission.status_values(),
      default: :pending

    belongs_to :actor, Banchan.Accounts.User
    belongs_to :commission, Banchan.Commissions.Commission
    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :data])
    |> validate_required([:type, :data])
  end
end
