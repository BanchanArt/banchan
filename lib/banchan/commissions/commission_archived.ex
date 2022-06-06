defmodule Banchan.Commissions.CommissionArchived do
  @moduledoc """
  Schema for tracking whether a user has archived a commission for themselves.
  """
  use Ecto.Schema

  schema "commission_archived" do
    field :archived, :boolean, default: false

    belongs_to :user, Banchan.Accounts.User
    belongs_to :commission, Banchan.Commissions.Commission

    timestamps()
  end
end
