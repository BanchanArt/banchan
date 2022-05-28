defmodule Banchan.Studios.Payout do
  @moduledoc """
  Payouts to Studios.
  """
  use Ecto.Schema

  schema "studio_payouts" do
    # https://stripe.com/docs/api/payouts/object#payout_object-id
    field :stripe_payout_id, :string

    # https://stripe.com/docs/api/payouts/object#payout_object-amount
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

    belongs_to :studio, Banchan.Studios.Studio
  end
end
