defmodule Banchan.Commissions.Event do
  @moduledoc """
  Main module for Commission Event data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Accounts.User
  alias Banchan.Commissions.{CommentHistory, Commission, Common, EventAttachment, Invoice}

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
    has_many :history, CommentHistory
    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :text, :amount, :status])
    |> validate_money(:amount)
    |> validate_required([:type])
    |> validate_text()
  end

  def text_changeset(event, attrs) do
    event
    |> cast(attrs, [:text])
    |> validate_text()
  end

  def amount_changeset(event, attrs) do
    event
    |> cast(attrs, [:amount])
    |> validate_money(:amount)
    |> validate_required([:amount])
  end

  def comment_changeset(event, attrs) do
    event
    |> cast(attrs, [:text])
    |> validate_required([:text])
    |> validate_text()
  end

  def invoice_changeset(event, attrs) do
    event
    |> cast(attrs, [:text, :amount])
    |> validate_money(:amount)
    |> validate_required([:amount])
    |> validate_text()
  end

  defp validate_text(changeset) do
    changeset
    |> validate_markdown(:text)
    |> validate_length(:text, max: 1500)
  end
end
