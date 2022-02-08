defmodule Banchan.Commissions.Commission do
  @moduledoc """
  Main module for Commission data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Commissions.Common

  schema "commissions" do
    field :public_id, :string, autogenerate: {Common, :gen_public_id, []}
    field :title, :string
    field :description, :string
    field :tos_ok, :boolean, virtual: true

    field :status, Ecto.Enum,
      values: Common.status_values(),
      default: :submitted

    has_many :line_items, Banchan.Commissions.LineItem,
      preload_order: [asc: :inserted_at],
      on_replace: :delete

    has_many :events, Banchan.Commissions.Event, preload_order: [asc: :inserted_at]
    belongs_to :offering, Banchan.Offerings.Offering
    belongs_to :studio, Banchan.Studios.Studio
    belongs_to :client, Banchan.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(commission, attrs) do
    commission
    |> cast(attrs, [:title, :description, :status, :tos_ok])
    |> cast_assoc(:line_items)
    |> cast_assoc(:events)
    |> validate_change(:tos_ok, fn field, tos_ok ->
      if tos_ok do
        []
      else
        [{field, "You must agree to the Terms and Conditions"}]
      end
    end)
    |> validate_required([:title, :description, :tos_ok])
  end
end
