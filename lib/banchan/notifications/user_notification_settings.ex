defmodule Banchan.Notifications.UserNotificationSettings do
  @moduledoc """
  User settings for how they'd like to receive relevant notifications.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User

  schema "user_notification_settings" do
    belongs_to :user, User

    # Notify on commission changes for commissions
    field :commission_email, :boolean, default: true
    field :commission_web, :boolean, default: true

    timestamps()
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:commission_email, :commission_web])
  end
end
