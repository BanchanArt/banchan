defmodule Banchan.Commissions.Commission do
  @moduledoc """
  Main module for Commission data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Commissions
  alias Banchan.Commissions.Common
  alias Banchan.Payments
  alias Banchan.Payments.Currency

  @description_max_length 1500

  schema "commissions" do
    field :public_id, :string, autogenerate: {Common, :gen_public_id, []}
    field :title, :string
    field :description, :string
    field :tos_ok, :boolean, virtual: true
    field :terms, :string
    field :currency, Ecto.Enum, values: Currency.supported_currencies()

    field :status, Ecto.Enum,
      values: Common.status_values(),
      default: :submitted

    has_many :line_items, Banchan.Commissions.LineItem,
      preload_order: [asc: :inserted_at, asc: :id],
      on_replace: :delete

    has_many :events, Banchan.Commissions.Event, preload_order: [asc: :inserted_at, asc: :id]

    belongs_to :offering, Banchan.Offerings.Offering
    belongs_to :studio, Banchan.Studios.Studio
    belongs_to :client, Banchan.Accounts.User

    timestamps()
  end

  @doc false
  def status_changeset(commission, attrs) do
    commission
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  @doc false
  def creation_changeset(commission, attrs) do
    commission
    |> cast(attrs, [:title, :description, :tos_ok, :currency])
    |> validate_required([:title, :description, :tos_ok, :currency])
    |> validate_length(:title, max: 50)
    |> validate_length(:description, max: @description_max_length)
    |> cast_assoc(:line_items)
    |> cast_assoc(:events)
    |> validate_line_items()
    |> validate_change(:tos_ok, fn field, tos_ok ->
      if tos_ok do
        []
      else
        [{field, "You must agree to the Terms and Conditions"}]
      end
    end)
  end

  @doc false
  def update_changeset(commission, attrs \\ %{}) do
    commission
    |> cast(attrs, [:title, :description])
    |> validate_length(:title, max: 50)
    |> validate_length(:description, max: @description_max_length)
    |> cast_assoc(:line_items)
    |> cast_assoc(:events)
    |> validate_line_items()
  end

  @doc false
  def update_title_changeset(commission, attrs \\ %{}) do
    commission
    |> cast(attrs, [:title])
    |> validate_length(:title, max: 50)
  end

  defp validate_line_items(changeset) do
    max = Payments.maximum_release_amount()

    changeset
    |> validate_change(:line_items, fn _, line_items ->
      estimate = Commissions.line_item_estimate(line_items)

      if Payments.cmp_money(max, estimate) in [:gt, :eq] do
        []
      else
        [
          {:line_items,
           "The maximum billable amount for commissions is #{Payments.print_money(max)}."}
        ]
      end
    end)
  end
end
