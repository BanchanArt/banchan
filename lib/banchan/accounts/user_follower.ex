defmodule Banchan.Accounts.UserFollower do
  @moduledoc """
  Data structure for whether a user follows another.
  """
  use Ecto.Schema

  alias Banchan.Accounts.User

  schema "user_followers" do
    belongs_to :user, User
    belongs_to :target, User
    timestamps()
  end
end
