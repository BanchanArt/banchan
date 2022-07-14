defmodule Banchan.Studios.Notifications do
  @moduledoc """
  Notifications for studio events.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Studios.{Payout, Studio, StudioFollower, StudioSubscription}

  @pubsub Banchan.PubSub

  def user_subscribed?(%User{} = user, %Studio{} = studio) do
    from(sub in StudioSubscription,
      where: sub.user_id == ^user.id and sub.studio_id == ^studio.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  def subscribe_user!(%User{} = user, %Studio{} = studio) do
    %StudioSubscription{user_id: user.id, studio_id: studio.id, silenced: false}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  def unsubscribe_user!(%User{} = user, %Studio{} = studio) do
    %StudioSubscription{user_id: user.id, studio_id: studio.id, silenced: true}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  def user_following?(%User{} = user, %Studio{} = studio) do
    from(sub in StudioFollower,
      where: sub.user_id == ^user.id and sub.studio_id == ^studio.id
    )
    |> Repo.exists?()
  end

  def follow_studio!(%Studio{} = studio, %User{} = user) do
    %StudioFollower{user_id: user.id, studio_id: studio.id}
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :studio_id])

    Notifications.with_task(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "follower_count:#{studio.handle}",
        %Phoenix.Socket.Broadcast{
          topic: "follower_count:#{studio.handle}",
          event: "follower_count_changed",
          payload: follower_count(studio)
        }
      )
    end)

    :ok
  end

  def unfollow_studio!(%Studio{} = studio, %User{} = user) do
    from(f in StudioFollower,
      where: f.user_id == ^user.id and f.studio_id == ^studio.id
    )
    |> Repo.delete_all()

    Notifications.with_task(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "follower_count:#{studio.handle}",
        %Phoenix.Socket.Broadcast{
          topic: "follower_count:#{studio.handle}",
          event: "follower_count_changed",
          payload: follower_count(studio)
        }
      )
    end)

    :ok
  end

  def follower_count(%Studio{} = studio) do
    from(f in StudioFollower,
      where: f.studio_id == ^studio.id,
      select: count(f)
    )
    |> Repo.one()
  end

  def following_count(%User{} = user) do
    from(f in StudioFollower,
      where: f.user_id == ^user.id,
      select: count(f)
    )
    |> Repo.one()
  end

  def subscribe_to_follower_count(%Studio{} = studio) do
    Phoenix.PubSub.subscribe(@pubsub, "follower_count:#{studio.handle}")
  end

  def unsubscribe_from_follower_count(%Studio{} = studio) do
    Phoenix.PubSub.unsubscribe(@pubsub, "follower_count:#{studio.handle}")
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
