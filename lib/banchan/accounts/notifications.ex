defmodule Banchan.Accounts.Notifications do
  @moduledoc """
  Notifications for account events.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.{User, UserFollower}
  alias Banchan.Repo

  def user_following?(%User{} = user, %User{} = target) do
    from(sub in UserFollower,
      where: sub.user_id == ^user.id and sub.target_id == ^target.id
    )
    |> Repo.exists?()
  end

  def follow_user!(%User{} = target, %User{} = user) do
    %UserFollower{user_id: user.id, target_id: target.id}
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :target_id])

    :ok
  end

  def unfollow_user!(%User{} = target, %User{} = user) do
    from(f in UserFollower,
      where: f.user_id == ^user.id and f.target_id == ^target.id
    )
    |> Repo.delete_all()

    :ok
  end

  def followers(%User{} = target) do
    from(
      u in User,
      join: user_sub in UserFollower,
      left_join: settings in assoc(u, :notification_settings),
      where: user_sub.target_id == ^target.id and u.id == user_sub.user_id,
      distinct: u.id,
      select: %User{
        id: u.id,
        email: u.email,
        notification_settings: settings
      }
    )
    |> Repo.stream()
  end

  def follower_count(%User{} = user) do
    from(f in UserFollower,
      where: f.target_id == ^user.id,
      select: count(f)
    )
    |> Repo.one()
  end

  def following_count(%User{} = user) do
    from(f in UserFollower,
      where: f.user_id == ^user.id,
      select: count(f)
    )
    |> Repo.one()
  end
end
