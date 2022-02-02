defmodule Banchan.Commissions.Event do
  @moduledoc """
  Main module for Commission Event data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Commission

  schema "commission_events" do
    field :type, Ecto.Enum, values: [:comment, :line_item, :payment_request, :status, :attachment]
    field :text, :string
    field :amount, Money.Ecto.Composite.Type

    field :status, Ecto.Enum,
      values: Commission.status_values(),
      default: :submitted

    belongs_to :actor, User
    belongs_to :commission, Commission
    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :text, :amount, :status])
    |> cast_assoc(:actor, required: true)
    |> cast_assoc(:commission)
    |> validate_required([:type])
  end
end
