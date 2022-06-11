defmodule Banchan.Commissions.Invoice do
  @moduledoc """
  Schema for individual Invoices within Commissions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "commission_invoices" do
    field :stripe_session_id, :string
    field :checkout_url, :string
    field :stripe_refund_id, :string
    field :amount, Money.Ecto.Composite.Type
    field :tip, Money.Ecto.Composite.Type
    field :platform_fee, Money.Ecto.Composite.Type
    field :payout_available_on, :utc_datetime
    field :required, :boolean

    field :refund_status, Ecto.Enum,
      values: [
        :pending,
        :succeeded,
        :failed,
        :canceled,
        :requires_action
      ]

    field :status, Ecto.Enum,
      values: [
        # Studio has requested payment. No other action taken.
        :pending,
        # Client has clicked through to Checkout.
        :submitted,
        # Checkout session has expired.
        :expired,
        # Payment succeeded but was then refunded
        :refunded,
        # Payment succeeded.
        :succeeded,
        # Invoice has succeeded and been released for payout
        :released
      ],
      default: :pending

    belongs_to :commission, Banchan.Commissions.Commission
    belongs_to :client, Banchan.Accounts.User
    belongs_to :event, Banchan.Commissions.Event

    many_to_many :payouts, Banchan.Studios.Payout, join_through: "invoices_payouts"

    timestamps()
  end

  @doc false
  def amount_changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount])
    |> validate_money(:amount)
    |> validate_required([:amount])
  end

  def creation_changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount, :required])
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
    |> cast(attrs, [
      :amount,
      :required,
      :tip,
      :platform_fee,
      :stripe_session_id,
      :checkout_url,
      :status
    ])
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
