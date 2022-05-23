defmodule Banchan.Notifications.UserNotification do
  @moduledoc """
  User notifications.
  """
  use Ecto.Schema

  alias Banchan.Accounts.User

  schema "user_notifications" do
    belongs_to :user, User
    field :type, :string
    field :title, :string
    field :body, :string
    field :url, :string
    field :read, :boolean
    timestamps()
  end
end
