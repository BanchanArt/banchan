defmodule Banchan.Notifications.CommissionSubscription do
  @moduledoc """
  User subscriptions to commission events.
  """
  use Ecto.Schema

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Commission

  schema "commission_subscriptions" do
    belongs_to :user, User
    belongs_to :commission, Commission
    timestamps()
  end
end
