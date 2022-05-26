defmodule Banchan.Commissions.Event do
  @moduledoc """
  Main module for Commission Event data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User
  alias Banchan.Commissions.{Commission, Common, EventAttachment, Invoice}

  schema "commission_events" do
    field :public_id, :string, autogenerate: {Common, :gen_public_id, []}

    field :type, Ecto.Enum, values: Common.event_types()
    field :text, :string
    field :amount, Money.Ecto.Composite.Type

    field :status, Ecto.Enum,
      values: Common.status_values(),
      default: :submitted

    belongs_to :actor, User
    belongs_to :commission, Commission
    has_one :invoice, Invoice
    has_many :attachments, EventAttachment
    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :text, :amount, :status])
    |> cast_assoc(:actor, required: true)
    |> cast_assoc(:commission)
    |> validate_money(:amount)
    |> validate_required([:type])
  end

  def text_changeset(event, attrs) do
    event |> cast(attrs, [:text])
  end

  def amount_changeset(event, attrs) do
    event
    |> cast(attrs, [:amount])
    |> validate_money(:amount)
    |> validate_required([:amount])
  end

  def comment_changeset(event, attrs) do
    event
    |> cast(attrs, [:text, :amount])
    |> validate_money(:amount)
    |> validate_required([:text])
  end

  defp validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 -> []
      _, "" -> []
      _, nil -> []
      _, _ -> [{field, "must be a non-negative amount"}]
    end)
  end
end
