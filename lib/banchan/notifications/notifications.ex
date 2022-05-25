defmodule Banchan.Notifications do
  @moduledoc """
  Context module for notification-related operations.
  """
  alias Bamboo.Email
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Commissions.{Commission, Common, Event}
  alias Banchan.Mailer

  alias Banchan.Notifications.{
    CommissionSubscription,
    StudioSubscription,
    UserNotification,
    UserNotificationSettings
  }

  alias Banchan.Repo
  alias Banchan.Studios.Studio

  # Unfortunate, but necessary to create URLs for notifications.
  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  @pubsub Banchan.PubSub

  # Whether to notify the actor themself of actions they take.
  # This is mostly intended to be used for testing the notification
  # system during development.
  @notify_actor false

  def new_commission(%Commission{} = commission, actor \\ nil) do
    start(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "commission",
        %Phoenix.Socket.Broadcast{
          topic: "commission",
          event: "new_commission",
          payload: commission
        }
      )

      {:ok, _} =
        Repo.transaction(fn ->
          subs = studio_subscribers(%Studio{id: commission.studio_id})

          notify_subscribers!(
            actor,
            subs,
            %UserNotification{
              type: "new_commission",
              title: commission.title,
              body: "A new commission has been submitted to your studio.",
              url: Routes.commission_url(Endpoint, :show, commission.public_id),
              read: false
            }
          )
        end)
    end)
  end

  def commission_event_updated(%Commission{} = commission, %Event{} = event, _actor \\ nil) do
    start(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "commission:#{commission.public_id}",
        %Phoenix.Socket.Broadcast{
          topic: "commission:#{commission.public_id}",
          event: "event_updated",
          payload: event
        }
      )

      # NOTE: No notifications in this case. event_updated is for things like
      # edits, that we don't want to spam users with.
    end)
  end

  def new_commission_events(%Commission{} = commission, events, actor \\ nil) do
    start(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "commission:#{commission.public_id}",
        %Phoenix.Socket.Broadcast{
          topic: "commission:#{commission.public_id}",
          event: "new_events",
          payload: events
        }
      )

      {:ok, _} =
        Repo.transaction(fn ->
          subs = commission_subscribers(commission)

          Enum.each(events, fn event ->
            url =
              Routes.commission_url(Endpoint, :show, commission.public_id)
              |> replace_fragment(event)

            notify_subscribers!(
              actor,
              subs,
              %UserNotification{
                type: "new_event",
                title: commission.title,
                body: new_event_notification_body(event),
                url: url,
                read: false
              },
              is_reply: true
            )
          end)
        end)
    end)
  end

  defp new_event_notification_body(%Event{
         type: :comment,
         actor: actor,
         actor_id: actor_id,
         text: body
       }) do
    %User{handle: handle} =
      if Ecto.assoc_loaded?(actor) do
        actor
      else
        Repo.one!(User, actor_id)
      end

    "#{handle} replied:\n\n#{body}"
  end

  defp new_event_notification_body(%Event{type: :line_item_added, amount: amount, text: text}) do
    "A new line item has been added to this commission:\n\n#{text}: #{Money.to_string(amount)}"
  end

  defp new_event_notification_body(%Event{type: :line_item_removed, amount: amount, text: text}) do
    "A line item has been removed from this commission:\n\n#{text}: #{Money.to_string(amount)}"
  end

  defp new_event_notification_body(%Event{type: :payment_processed, amount: amount}) do
    "A payment for #{Money.to_string(amount)} has been successfully processed. It will be available for payout when the commission is completed and accepted."
  end

  defp new_event_notification_body(%Event{type: :status, status: status}) do
    "The commission status has been changed to #{Common.humanize_status(status)}."
  end

  def commission_status_changed(%Commission{} = commission, _actor \\ nil) do
    start(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "commission:#{commission.public_id}",
        %Phoenix.Socket.Broadcast{
          topic: "commission:#{commission.public_id}",
          event: "new_status",
          payload: commission.status
        }
      )

      # NOTE: No notifications in this case. event_updated is for things like
      # edits, that we don't want to spam users with.
    end)
  end

  def commission_line_items_changed(%Commission{} = commission, _actor \\ nil) do
    start(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "commission:#{commission.public_id}",
        %Phoenix.Socket.Broadcast{
          topic: "commission:#{commission.public_id}",
          event: "line_items_changed",
          payload: commission.line_items
        }
      )

      # NOTE: No notification here because new_events takes care of notifying
      # about this already.
    end)
  end

  def mark_all_as_read(%User{} = user) do
    from(notification in UserNotification,
      where: notification.user_id == ^user.id
    )
    |> Repo.update_all(set: [read: true])

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "notification:#{user.handle}",
      %Phoenix.Socket.Broadcast{
        topic: "notification:#{user.handle}",
        event: "all_notifications_read",
        payload: nil
      }
    )
  end

  def mark_notification_read(%User{} = user, notification_ref) do
    from(notification in UserNotification,
      where: notification.user_id == ^user.id and notification.ref == ^notification_ref
    )
    |> Repo.update_all(set: [read: true])

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "notification:#{user.handle}",
      %Phoenix.Socket.Broadcast{
        topic: "notification:#{user.handle}",
        event: "notification_read",
        payload: notification_ref
      }
    )
  end

  def update_user_notification_settings(%User{id: user_id}, attrs) do
    %UserNotificationSettings{
      user_id: user_id,
      updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    }
    |> UserNotificationSettings.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:user_id]
    )
  end

  def user_subscribed?(%User{} = user, %Commission{} = commission) do
    from(sub in CommissionSubscription,
      where:
        sub.user_id == ^user.id and sub.commission_id == ^commission.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  def user_subscribed?(%User{} = user, %Studio{} = studio) do
    from(sub in StudioSubscription,
      where: sub.user_id == ^user.id and sub.studio_id == ^studio.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  def subscribe_user!(%User{} = user, %Commission{} = comm) do
    %CommissionSubscription{user: user, commission: comm, silenced: false}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :commission_id]
    )
  end

  def subscribe_user!(%User{id: user_id}, %Studio{id: studio_id}) do
    %StudioSubscription{user_id: user_id, studio_id: studio_id, silenced: false}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  def unsubscribe_user!(%User{} = user, %Commission{} = comm) do
    %CommissionSubscription{user: user, commission: comm, silenced: true}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :commission_id]
    )
  end

  def unsubscribe_user!(%User{} = user, %Studio{} = studio) do
    %StudioSubscription{user: user, studio: studio, silenced: true}
    |> Repo.insert(on_conflict: {:replace, [:silenced]}, conflict_target: [:user_id, :studio_id])
  end

  def unread_notifications(%User{} = user, page) do
    from(
      n in UserNotification,
      where: n.user_id == ^user.id and n.read == false,
      order_by: {:desc, n.updated_at}
    )
    |> Repo.paginate(page: page, page_size: 20)
  end

  def subscribe_to_notifications(%User{} = user) do
    Phoenix.PubSub.subscribe(@pubsub, "notification:#{user.handle}")
  end

  def unsubscribe_from_notifications(%User{} = user) do
    Phoenix.PubSub.unsubscribe(@pubsub, "notification:#{user.handle}")
  end

  defp start(task) do
    Task.Supervisor.start_child(Banchan.NotificationTaskSupervisor, task)
  end

  defp notify_subscribers!(actor, subs, %UserNotification{} = notification, opts \\ []) do
    {:ok, _} =
      Repo.transaction(fn ->
        Enum.each(subs, fn %User{
                             id: id,
                             handle: handle,
                             email: email,
                             notification_settings: settings
                           } ->
          if settings.commission_web && ((actor && actor.id != id) || @notify_actor) do
            notification = Repo.insert!(%{notification | user_id: id}, returning: [:ref])

            Phoenix.PubSub.broadcast!(
              @pubsub,
              "notification:#{handle}",
              %Phoenix.Socket.Broadcast{
                topic: "notification:#{handle}",
                event: "new_notification",
                payload: notification
              }
            )
          end

          if settings.commission_email && ((actor && actor.id != id) || @notify_actor) do
            send_email(email, notification, opts)
          end
        end)
      end)
  end

  defp send_email(email, %UserNotification{} = notification, opts) do
    title =
      if Keyword.get(opts, :is_reply, false) do
        "Re: " <> notification.title
      else
        notification.title
      end

    {:safe, html_url} = Phoenix.HTML.html_escape(notification.url)

    Email.new_email(
      to: email,
      from: "notifications@" <> (System.get_env("SENDGRID_DOMAIN") || "noreply.banchan.art"),
      subject: title,
      html_body: notification.body <> "\n\n<a href=\"#{html_url}\">Details</a>",
      text_body: notification.body <> "\n\n" <> notification.url
    )
    |> Mailer.deliver_later!()
  end

  defp studio_subscribers(%Studio{} = studio) do
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

  defp commission_subscribers(%Commission{} = commission) do
    from(
      u in User,
      join: comm_sub in CommissionSubscription,
      join: studio_sub in StudioSubscription,
      left_join: settings in assoc(u, :notification_settings),
      where:
        ((comm_sub.commission_id == ^commission.id and u.id == comm_sub.user_id) or
           (studio_sub.studio_id == ^commission.studio_id and u.id == studio_sub.user_id)) and
          (comm_sub.silenced != true or
             (studio_sub.studio_id != ^commission.studio_id and u.id != studio_sub.user_id and
                studio_sub.silenced != true)),
      distinct: u.id,
      select: %User{
        id: u.id,
        handle: u.handle,
        email: u.email,
        notification_settings: settings
      }
    )
    |> Repo.stream()
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end
end
