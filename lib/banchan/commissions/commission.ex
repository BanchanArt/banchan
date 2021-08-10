defmodule Banchan.Commissions.Commission do
  @moduledoc """
  Main module for Commission data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "commissions" do
    # TODO(zkat): we need some kind of ID here that we can expose to customers?
    field :title, :string

    field :status, Ecto.Enum,
      values: [:pending, :accepted, :in_progress, :paused, :waiting, :closed],
      default: :pending

    belongs_to :studio, Banchan.Studios.Studio
    belongs_to :client, Banchan.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(commission, attrs) do
    commission
    |> cast(attrs, [:title, :status])
    |> validate_required([:title, :status])
  end
end
