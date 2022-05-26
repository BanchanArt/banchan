defmodule Banchan.Notifications.UserNotification do
  @moduledoc """
  User notifications.
  """
  use Ecto.Schema

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Common

  schema "user_notifications" do
    field :ref, :string, autogenerate: {Common, :gen_public_id, []}
    belongs_to :user, User
    field :type, :string
    field :title, :string
    field :short_body, :string
    field :text_body, :string
    field :html_body, :string
    field :url, :string
    field :read, :boolean
    timestamps()
  end
end
