defmodule Banchan.Offerings.OfferingSubscription do
  @moduledoc """
  User subscriptions to offering events.
  """
  use Ecto.Schema

  alias Banchan.Accounts.User
  alias Banchan.Offerings.Offering

  schema "offering_subscriptions" do
    belongs_to :user, User
    belongs_to :offering, Offering
    field :silenced, :boolean
    timestamps()
  end
end
