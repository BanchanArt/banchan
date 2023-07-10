defmodule Banchan.Payments.Invoice do
  @moduledoc """
  Schema for individual Invoices within Commissions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Payments

  schema "commission_invoices" do
    field :stripe_session_id, :string
    field :checkout_url, :string
    field :stripe_refund_id, :string
    field :stripe_charge_id, :string
    field :amount, Money.Ecto.Composite.Type
    field :tip, Money.Ecto.Composite.Type
    field :deposited, Money.Ecto.Composite.Type
    field :platform_fee, Money.Ecto.Composite.Type
    field :total_charged, Money.Ecto.Composite.Type
    field :total_transferred, Money.Ecto.Composite.Type
    field :payout_available_on, :utc_datetime
    field :paid_on, :utc_datetime
    field :required, :boolean
    field :final, :boolean

    field :refund_status, Ecto.Enum,
      values: [
        :pending,
        :succeeded,
        :failed,
        :canceled,
        :requires_action
      ]

    field :refund_failure_reason, Ecto.Enum,
      values: [
        :lost_or_stolen_card,
        :expired_or_canceled_card,
        :unknown
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

    belongs_to :refunded_by, Banchan.Accounts.User
    belongs_to :commission, Banchan.Commissions.Commission
    belongs_to :client, Banchan.Accounts.User
    belongs_to :event, Banchan.Commissions.Event

    many_to_many :payouts, Banchan.Payments.Payout, join_through: "invoices_payouts"

    embeds_many :line_items, LineItem do
      field :amount, Money.Ecto.Map.Type
      field :name, :string
      field :description, :string
    end

    timestamps()
  end

  @doc false
  def amount_changeset(payment, attrs) do
    min = Payments.minimum_transaction_amount()

    payment
    |> cast(attrs, [:amount])
    |> validate_money(:amount)
    |> validate_required([:amount])
    |> validate_change(:amount, fn _, amount ->
      if Payments.cmp_money(min, amount) in [:lt, :eq] do
        []
      else
        [
          {:amount,
           "must be at least #{Payments.convert_money(min, amount.currency) |> Money.to_string()}"}
        ]
      end
    end)
  end

  def creation_changeset(payment, attrs, %Money{} = remaining) do
    min = Payments.minimum_transaction_amount()

    payment
    |> cast(attrs, [:amount, :required, :deposited])
    |> cast_embed(:line_items, with: &line_item_changeset/2, required: true)
    |> validate_money(:amount, remaining)
    |> validate_money(:deposited)
    |> validate_required([:amount, :deposited])
    |> validate_change(:amount, fn _, amount ->
      if Payments.cmp_money(min, amount) in [:lt, :eq] do
        []
      else
        [
          {:amount,
           "must be at least #{Payments.convert_money(min, amount.currency) |> Money.to_string()}"}
        ]
      end
    end)
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
    min = Payments.minimum_transaction_amount()

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
    |> validate_money(:amount)
    |> validate_money(:tip)
    |> validate_money(:platform_fee)
    |> validate_change(:amount, fn _, amount ->
      if Payments.cmp_money(min, amount) in [:lt, :eq] do
        []
      else
        [
          {:amount,
           "must be at least #{Payments.convert_money(min, amount.currency) |> Money.to_string()}"}
        ]
      end
    end)
    |> validate_required([
      :amount,
      :tip,
      :platform_fee,
      :stripe_session_id,
      :checkout_url,
      :status
    ])
  end

  defp line_item_changeset(schema, params) do
    schema
    |> cast(params, [:amount, :name, :description])
    |> validate_money(:amount)
    |> validate_required([
      :amount,
      :name,
      :description
    ])
  end
end
