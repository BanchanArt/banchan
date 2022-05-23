defmodule Banchan.Notifications.StudioSubscription do
  @moduledoc """
  User subscriptions to commission events, at the studio level.
  """
  use Ecto.Schema

  alias Banchan.Accounts.User
  alias Banchan.Studios.Studio

  schema "studio_subscriptions" do
    belongs_to :user, User
    belongs_to :studio, Studio
    timestamps()
  end
end
