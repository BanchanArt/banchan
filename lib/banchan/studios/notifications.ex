defmodule Banchan.Studios.Notifications do
  @moduledoc """
  Notifications for studio events.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Studios.{Payout, Studio, StudioSubscription}

  @pubsub Banchan.PubSub

  def user_subscribed?(%User{} = user, %Studio{} = studio) do
    from(sub in StudioSubscription,
      where: sub.user_id == ^user.id and sub.studio_id == ^studio.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  def subscribe_user!(%User{id: user_id}, %Studio{id: studio_id}) do
    %StudioSubscription{user_id: user_id, studio_id: studio_id, silenced: false}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  def unsubscribe_user!(%User{} = user, %Studio{} = studio) do
    %StudioSubscription{user: user, studio: studio, silenced: true}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  def subscribers(%Studio{} = studio) do
    from(
      u in User,
      join: studio_sub in StudioSubscription,
      left_join: settings in assoc(u, :notification_settings),
      where:
        studio_sub.studio_id == ^studio.id and u.id == studio_sub.user_id and
          studio_sub.silenced != true,
      distinct: u.id,
      select: %User{
        id: u.id,
        email: u.email,
        notification_settings: settings
      }
    )
    |> Repo.stream()
  end

  def payout_updated(%Payout{} = payout, _actor \\ nil) do
    Notifications.with_task(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "payout:#{payout.studio.handle}",
        %Phoenix.Socket.Broadcast{
          topic: "payout:#{payout.studio.handle}",
          event: "payout_updated",
          payload: payout
        }
      )
    end)
  end
end
