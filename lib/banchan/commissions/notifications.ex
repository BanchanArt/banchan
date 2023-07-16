defmodule Banchan.Commissions.Notifications do
  @moduledoc """
  Notifications for commission events.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, CommissionSubscription, Common, Event}
  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Studios.{Studio, StudioSubscription}

  # Unfortunate, but needed for crafting URLs for notifications
  use BanchanWeb, :verified_routes

  @pubsub Banchan.PubSub

  @doc """
  True if the user is directly subscribed to the given Commission.
  """
  def user_subscribed?(%User{} = user, %Commission{} = commission) do
    from(sub in CommissionSubscription,
      where:
        sub.user_id == ^user.id and sub.commission_id == ^commission.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  @doc """
  Subscribes the user to commission notifications.
  """
  def subscribe_user!(%User{} = user, %Commission{} = comm) do
    %CommissionSubscription{user_id: user.id, commission_id: comm.id, silenced: false}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :commission_id]
    )
  end

  @doc """
  Unsubscribes a user from commission notifications.
  """
  def unsubscribe_user!(%User{} = user, %Commission{} = comm) do
    %CommissionSubscription{user_id: user.id, commission_id: comm.id, silenced: true}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :commission_id]
    )
  end

  @doc """
  Returns a stream of the commission's applicable subscribers. Note that this also takes
  into account Studio subscriptions, so unless a Studio member has explicitly
  silenced the commission, they'll receive updates if they're subscribed to
  Studio notifications.
  """
  def subscribers(%Commission{} = commission) do
    from(
      u in User,
      join: comm_sub in CommissionSubscription,
      on: true,
      join: studio_sub in StudioSubscription,
      on: true,
      left_join: settings in assoc(u, :notification_settings),
      on: true,
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

  @doc """
  Sends out notifications about new commissions.
  """
  def new_commission(%Commission{} = commission, actor \\ nil) do
    Notifications.with_task(fn ->
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
          subs = Studios.Notifications.subscribers(%Studio{id: commission.studio_id})

          url = url(~p"/commissions/#{commission.public_id}")
          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            subs,
            %Notifications.UserNotification{
              type: "new_commission",
              title: commission.title,
              short_body: "A new commission has been submitted to your studio.",
              text_body: "A new commission has been submitted to your studio.\n\n#{url}",
              html_body:
                "<p>A new commission has been submitted to your studio.</p><p><a href=\"#{safe_url}\">View it</a></p>",
              url: url,
              read: false
            }
          )
        end)
    end)
  end

  @doc """
  Broadcasts a notification that a specific event in a commission has been
  updated. This might be things like comments being edited, upload thumbnails
  completing, etc.
  """
  def commission_event_updated(comm, ev, _actor \\ nil)

  def commission_event_updated(%Commission{} = commission, %Event{} = event, _actor) do
    Notifications.with_task(fn ->
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

  # This clause is specifically used when attachment thumbnails complete.
  def commission_event_updated(commission_id, event_id, _actor)
      when is_number(commission_id) and is_number(event_id) do
    commission_event_updated(
      %Commission{public_id: Commissions.get_public_id!(commission_id)},
      Repo.get!(Event, event_id)
      |> Repo.preload(attachments: [:upload, :preview, :thumbnail], invoice: [])
    )
  end

  @doc """
  Broadcasts a list of events that have been added to a commission.
  """
  def new_commission_events(%Commission{} = commission, events, actor \\ nil) do
    Notifications.with_task(fn ->
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
          subs = subscribers(commission)

          Enum.each(events, fn event ->
            url =
              url(~p"/commissions/#{commission.public_id}")
              |> replace_fragment(event)

            body = new_event_notification_body(event)
            {:safe, safe_body} = Phoenix.HTML.html_escape(body)
            {:safe, safe_url} = Phoenix.HTML.html_escape(url)

            Notifications.notify_subscribers!(
              actor,
              subs,
              %Notifications.UserNotification{
                type: "new_event",
                title: commission.title,
                short_body: body,
                text_body: "#{body}\n\n#{url}",
                html_body: "<p>#{safe_body}</p><p><a href=\"#{safe_url}\">View it</a></p>",
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
        Repo.get!(User, actor_id)
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
    "A payment for #{Money.to_string(amount)} has been successfully processed."
  end

  defp new_event_notification_body(%Event{type: :refund_processed, amount: amount}) do
    "A refund for #{Money.to_string(amount)} has been issued successfully. Funds should clear in 5-10 days."
  end

  defp new_event_notification_body(%Event{type: :status, status: status}) do
    "The commission status has been changed to #{Common.humanize_status(status)}."
  end

  defp new_event_notification_body(%Event{type: :all_invoices_released}) do
    "All deposits for the commission have been released."
  end

  defp new_event_notification_body(%Event{type: :invoice_released}) do
    "An invoice deposit has been released to the studio."
  end

  @doc """
  Broadcasts commission title changes so commission pages can live-update.
  """
  def commission_title_changed(%Commission{} = commission, _actor \\ nil) do
    Notifications.with_task(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "commission:#{commission.public_id}",
        %Phoenix.Socket.Broadcast{
          topic: "commission:#{commission.public_id}",
          event: "new_title",
          payload: commission.title
        }
      )
    end)
  end

  @doc """
  Broadcasts commission status changes so commission pages can live-update.
  """
  def commission_status_changed(%Commission{} = commission, _actor \\ nil) do
    Notifications.with_task(fn ->
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

  @doc """
  Broadcasts commission line item changes so commission pages can live-update.
  """
  def commission_line_items_changed(%Commission{} = commission, _actor \\ nil) do
    Notifications.with_task(fn ->
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

  @doc """
  Sends out web/email notifications only, when a commission has been finalized
  and all invoices have been released.
  """
  def commission_approved(%Commission{} = commission, actor \\ nil) do
    # No need for a broadcast. That's already being handled by commission_event_updated
    Notifications.with_task(fn ->
      {:ok, _} =
        Repo.transaction(fn ->
          subs = subscribers(commission)

          url = url(~p"/commissions/#{commission.public_id}")

          body =
            "The commission has been approved. All deposits and attachments have been released."

          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            subs,
            %Notifications.UserNotification{
              type: "commission_approved",
              title: commission.title,
              short_body: body,
              text_body: "#{body}\n\n#{url}",
              html_body: "<p>#{body}</p><p><a href=\"#{safe_url}\">View it</a></p>",
              url: url,
              read: false
            },
            is_reply: true
          )
        end)
    end)
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end
end
