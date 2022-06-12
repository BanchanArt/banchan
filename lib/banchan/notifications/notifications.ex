defmodule Banchan.Notifications do
  @moduledoc """
  Context module for notification-related operations.
  """
  alias Bamboo.Email
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Mailer

  alias Banchan.Notifications.{
    UserNotification,
    UserNotificationSettings
  }

  alias Banchan.Repo

  @pubsub Banchan.PubSub

  # Whether to notify the actor themself of actions they take.
  # This is mostly intended to be used for testing the notification
  # system during development.
  @notify_actor false

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

  def get_notification_settings(%User{} = user) do
    Repo.one(from(settings in UserNotificationSettings, where: settings.user_id == ^user.id))
  end

  def update_user_notification_settings(%User{id: user_id}, attrs) do
    %UserNotificationSettings{
      user_id: user_id
    }
    |> UserNotificationSettings.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:user_id]
    )
  end

  def unread_notifications(%User{} = user, page \\ 1) do
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

  def wait_for_notifications do
    Task.Supervisor.children(Banchan.NotificationTaskSupervisor)
    |> Enum.map(&Process.monitor/1)
    |> Enum.each(fn ref ->
      receive do
        # Order doesn't matter
        {:DOWN, ^ref, _, _, _} ->
          nil
      end
    end)
  end

  def with_task(task) do
    Task.Supervisor.start_child(Banchan.NotificationTaskSupervisor, task)
  end

  # Not bothering with this one.
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def notify_subscribers!(actor, subs, %UserNotification{} = notification, opts \\ []) do
    {:ok, _} =
      Repo.transaction(fn ->
        Enum.each(subs, fn %User{
                             id: id,
                             handle: handle,
                             email: email,
                             notification_settings: settings
                           } ->
          notify_actor = (actor && actor.id != id) || @notify_actor

          web_setting = is_nil(settings) || settings.commission_web

          if web_setting && (!actor || notify_actor) do
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

          email_setting = is_nil(settings) || settings.commission_email

          if email_setting && (!actor || notify_actor) do
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

    Email.new_email(
      to: email,
      from: "notifications@" <> (System.get_env("SENDGRID_DOMAIN") || "noreply.banchan.art"),
      subject: title,
      html_body: notification.html_body,
      text_body: notification.text_body
    )
    |> Mailer.deliver_later!()
  end
end
