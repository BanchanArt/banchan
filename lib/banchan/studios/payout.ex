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

    # https://stripe.com/docs/api/payouts/failures
    field :failure_code, Ecto.Enum,
      values: [
        :account_closed,
        :account_frozen,
        :bank_account_restricted,
        :bank_ownership_changed,
        :could_not_process,
        :debit_not_authorized,
        :declined,
        :insufficient_funds,
        :invalid_account_number,
        :incorrect_account_holder_name,
        :incorrect_account_holder_address,
        :incorrect_account_holder_tax_id,
        :invalid_currency,
        :no_account,
        :unsupported_card
      ]

    field :failure_message, :string

    belongs_to :studio, Banchan.Studios.Studio

    many_to_many :invoices, Banchan.Commissions.Invoice, join_through: "invoices_payouts"
  end
end
