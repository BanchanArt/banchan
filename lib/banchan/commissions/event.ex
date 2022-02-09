defmodule Banchan.Commissions.Event do
  @moduledoc """
  Main module for Commission Event data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User
  alias Banchan.Commissions.{Commission, Common, EventAttachment}

  schema "commission_events" do
    field :public_id, :string, autogenerate: {Common, :gen_public_id, []}

    field :type, Ecto.Enum,
      values: [
        # No added/edited/removed variant because these are mutable.
        :comment,
        :line_item_added,
        :line_item_removed,
        :payment_request,
        :payment_processed,
        :status
      ]

    field :text, :string
    field :amount, Money.Ecto.Composite.Type

    field :status, Ecto.Enum,
      values: Common.status_values(),
      default: :submitted

    belongs_to :actor, User
    belongs_to :commission, Commission
    has_many :attachments, EventAttachment
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

  def text_changeset(event, attrs) do
    event |> cast(attrs, [:text])
  end
end
