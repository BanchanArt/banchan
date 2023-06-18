defmodule Banchan.Studios.Notifications do
  @moduledoc """
  Notifications for studio events.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Studios.{Studio, StudioFollower, StudioSubscription}
  alias Banchan.Workers.Mailer

  @pubsub Banchan.PubSub

  @doc """
  True if the user is currently subscribed to Studio notifications (as in, new
  Studio commissions). `user` must be a Studio member for these notifications
  to work.
  """
  def user_subscribed?(%User{} = user, %Studio{} = studio) do
    from(sub in StudioSubscription,
      where: sub.user_id == ^user.id and sub.studio_id == ^studio.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  @doc """
  Subscribes the user to Studio notifications (as in, new Studio commissions and such).
  """
  def subscribe_user!(%User{} = user, %Studio{} = studio) do
    %StudioSubscription{user_id: user.id, studio_id: studio.id, silenced: false}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  @doc """
  Unsubscribes the user from the given studio, if they're subscribed.
  """
  def unsubscribe_user!(%User{} = user, %Studio{} = studio) do
    %StudioSubscription{user_id: user.id, studio_id: studio.id, silenced: true}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  @doc """
  Whether a user is following a Studio. Followers are more like
  fans/subscribers to the studio itself and will be notified of things like
  new offerings, receive broadcasts, etc.
  """
  def user_following?(%User{} = user, %Studio{} = studio) do
    from(sub in StudioFollower,
      where: sub.user_id == ^user.id and sub.studio_id == ^studio.id
    )
    |> Repo.exists?()
  end

  @doc """
  Paginated view of followers for a given studio.
  """
  def list_followers(%Studio{} = studio, opts \\ []) do
    from(u in User,
      as: :user,
      join: f in StudioFollower,
      on: f.user_id == u.id and f.studio_id == ^studio.id,
      where: is_nil(u.deactivated_at),
      order_by: [desc: f.inserted_at],
      preload: [:header_img, :pfp_thumb]
    )
    |> Repo.paginate(
      page_size: Keyword.get(opts, :page_size, 24),
      page: Keyword.get(opts, :page, 1)
    )
  end

  @doc """
  Adds a user to the given studio's followers.
  """
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

  @doc """
  Removes a user from the given studio's followers.
  """
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

  @doc """
  Number of active followers for a Studio.
  """
  def follower_count(%Studio{} = studio) do
    from(f in StudioFollower,
      where: f.studio_id == ^studio.id,
      select: count(f)
    )
    |> Repo.one()
  end

  @doc """
  Number of Studios this user is currently following.
  """
  def following_count(%User{} = user) do
    from(f in StudioFollower,
      where: f.user_id == ^user.id,
      select: count(f)
    )
    |> Repo.one()
  end

  @doc """
  Subscribes the current process to follower count events. This allows
  live-updates for the follower count on Studio pages.
  """
  def subscribe_to_follower_count(%Studio{} = studio) do
    Phoenix.PubSub.subscribe(@pubsub, "follower_count:#{studio.handle}")
  end

  @doc """
  Unsubscribes the current process from follower count events.
  """
  def unsubscribe_from_follower_count(%Studio{} = studio) do
    Phoenix.PubSub.unsubscribe(@pubsub, "follower_count:#{studio.handle}")
  end

  @doc """
  Returns a stream of active subscribers to the Studio. This is the list of
  Studio members who have opted to receive notifications about the Studio
  itself (new commissions, etc).
  """
  def subscribers(%Studio{} = studio) do
    from(
      u in User,
      join: studio_sub in StudioSubscription,
      on: true,
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

  @doc """
  Notifies studio members that a studio has been deleted successfully.
  """
  def studio_deleted(%User{} = actor, %Studio{} = studio) do
    Studios.list_studio_members(studio)
    |> Enum.each(fn member ->
      if member.email do
        Mailer.new_email(
          member.email,
          "Your Studio has been successfully deleted",
          BanchanWeb.Email.StudiosView,
          :studio_deleted,
          actor: actor,
          member: member,
          studio: studio
        )
        |> Mailer.deliver()
      end
    end)
  end
end
