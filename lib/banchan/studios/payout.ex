defmodule Banchan.Studios.Payout do
  @moduledoc """
  Payouts to Studios.
  """
  use Ecto.Schema

  schema "studio_payouts" do
    field :stripe_payout_id, :string
    field :amount, Money.Ecto.Composite.Type

    # https://stripe.com/docs/api/payouts/object#payout_object-status
    field :status, Ecto.Enum,
      values: [
        :pending,
        :in_transit,
        :canceled,
        :paid,
        :failed
      ],
      default: :pending

    field :failure_code, :string
    field :failure_message, :string

    belongs_to :studio, Banchan.Studios.Studio
  end
end
