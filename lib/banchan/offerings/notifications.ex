defmodule Banchan.Offerings.Notifications do
  @moduledoc """
  Notifications related to offerings (new slots opening, etc.)
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Offerings.{Offering, OfferingSubscription}
  alias Banchan.Studios.{StudioFollower, StudioSubscription}

  # Unfortunate, but needed for crafting URLs for notifications
  use BanchanWeb, :verified_routes

  @pubsub Banchan.PubSub

  def user_subscribed?(%User{} = user, %Offering{} = offering) do
    from(sub in OfferingSubscription,
      where: sub.user_id == ^user.id and sub.offering_id == ^offering.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  def subscribe_user!(%User{} = user, %Offering{} = offering) do
    %OfferingSubscription{user_id: user.id, offering_id: offering.id, silenced: false}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :offering_id]
    )
  end

  def unsubscribe_user!(%User{} = user, %Offering{} = offering) do
    %OfferingSubscription{user_id: user.id, offering_id: offering.id, silenced: true}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :offering_id]
    )
  end

  def subscribers(%Offering{} = offering) do
    from(
      u in User,
      left_join: offering_sub in OfferingSubscription,
      on: offering_sub.offering_id == ^offering.id and u.id == offering_sub.user_id,
      left_join: studio_sub in StudioFollower,
      on: studio_sub.studio_id == ^offering.studio_id and u.id == studio_sub.user_id,
      left_join: settings in assoc(u, :notification_settings),
      where:
        (not is_nil(offering_sub.id) and offering_sub.silenced != true) or
          not is_nil(studio_sub.id),
      distinct: u.id,
      select: %User{
        id: u.id,
        email: u.email,
        notification_settings: settings
      }
    )
    |> Repo.stream()
  end

  def offering_opened(%Offering{} = offering, actor \\ nil) do
    Notifications.with_task(fn ->
      {:ok, _} =
        Repo.transaction(fn ->
          subs = subscribers(offering)

          studio = Repo.preload(offering, :studio).studio

          url = url(~p"/studios/#{studio.handle}/offerings/#{offering.type}")

          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            subs,
            %Notifications.UserNotification{
              type: "offering_open",
              title: "Commission slots now available!",
              short_body:
                "Commission slots are now available for '#{offering.name}' from #{studio.name}.",
              text_body:
                "Commission slots are now available for '#{offering.name}' from #{studio.name}.\n\n#{url}",
              html_body:
                "<p>Commission slots are now available for '#{offering.name}' from #{studio.name}.</p><p><a href=\"#{safe_url}\">View it</a></p>",
              url: url,
              read: false
            }
          )
        end)
    end)
  end

  def offering_closed(%Offering{} = offering, actor \\ nil) do
    Notifications.with_task(fn ->
      {:ok, _} =
        Repo.transaction(fn ->
          subs = closure_notifiants(offering)

          studio = Repo.preload(offering, :studio).studio

          url = url(~p"/studios/#{studio.handle}/offerings/#{offering.type}")

          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            subs,
            %Notifications.UserNotification{
              type: "offering_closed",
              title: "Offering has closed!",
              short_body: "'#{offering.name}' from #{studio.name} is now closed.",
              text_body: "'#{offering.name}' from #{studio.name} is now closed.\n\n#{url}",
              html_body:
                "<p>'#{offering.name}' from #{studio.name} is now closed.</p><p><a href=\"#{safe_url}\">View it</a></p>",
              url: url,
              read: false
            }
          )
        end)
    end)
  end

  defp closure_notifiants(%Offering{} = offering) do
    from(
      u in User,
      join: us in "users_studios",
      on: us.studio_id == ^offering.studio_id,
      left_join: settings in assoc(u, :notification_settings),
      left_join: studio_sub in StudioSubscription,
      on: studio_sub.studio_id == ^offering.studio_id and u.id == studio_sub.user_id,
      left_join: offering_sub in OfferingSubscription,
      on: offering_sub.offering_id == ^offering.id and u.id == offering_sub.user_id,
      where:
        (not is_nil(offering_sub.id) and offering_sub.silenced != true) or
          (not is_nil(studio_sub.id) and studio_sub.silenced != true) or
          (us.user_id == u.id and is_nil(studio_sub.id)),
      distinct: u.id,
      select: %User{
        id: u.id,
        email: u.email,
        notification_settings: settings
      }
    )
    |> Repo.stream()
  end

  def subscribe_to_offering_updates(%Offering{} = offering) do
    topic = "offering:#{offering.studio.handle}:#{offering.type}"
    Phoenix.PubSub.subscribe(@pubsub, topic)
  end

  def unsubscribe_from_offering_updates(%Offering{} = offering) do
    topic = "offering:#{offering.studio.handle}:#{offering.type}"
    Phoenix.PubSub.unsubscribe(@pubsub, topic)
  end
end
