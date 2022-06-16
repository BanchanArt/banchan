defmodule Banchan.Studios.StudioFollower do
  @moduledoc """
  Notifications for studio followers.
  """
  use Ecto.Schema

  alias Banchan.Accounts.User
  alias Banchan.Studios.Studio

  schema "studio_followers" do
    belongs_to :user, User
    belongs_to :studio, Studio
    timestamps()
  end
end
