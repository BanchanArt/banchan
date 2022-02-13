defmodule Banchan.Commissions.PaymentRequest do
  @moduledoc """
  Schema for payment requests within Commissions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "commission_payment_requests" do
    field :stripe_session_id, :string
    field :checkout_url, :string
    field :amount, Money.Ecto.Composite.Type
    field :tip, Money.Ecto.Composite.Type
    field :platform_fee, Money.Ecto.Composite.Type

    field :status, Ecto.Enum,
      values: [
        # Studio has requested payment. No other action taken.
        :pending,
        # Client has clicked through to Checkout.
        :submitted,
        # Payment was canceled.
        :canceled,
        # Payment succeeded.
        :succeeded,
        # Payment amount has been paid out to Studio.
        :paid_out
      ],
      default: :pending

    belongs_to :commission, Banchan.Commissions.Commission
    belongs_to :client, Banchan.Accounts.User
    belongs_to :event, Banchan.Commissions.Event

    timestamps()
  end

  @doc false
  def amount_changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount])
    |> validate_money(:amount)
    |> validate_required([:amount])
  end

  @doc false
  def tip_changeset(payment, attrs) do
    payment
    |> cast(attrs, [:tip])
    |> validate_money(:tip)
    |> validate_required([:tip])
  end

  @doc false
  def submit_changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount, :tip, :platform_fee, :stripe_session_id, :checkout_url, :status])
    |> validate_money(:tip)
    |> validate_money(:platform_fee)
    |> validate_required([
      :amount,
      :tip,
      :platform_fee,
      :stripe_session_id,
      :checkout_url,
      :status
    ])
  end

  defp validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 -> []
      _, _ -> [{field, "must be a positive amount"}]
    end)
  end
end
