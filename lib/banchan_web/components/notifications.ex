defmodule BanchanWeb.Components.Notifications do
  @moduledoc """
  Notification display.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveRedirect

  alias Banchan.Notifications
  alias Banchan.Notifications.UserNotification

  alias BanchanWeb.Components.Icon

  prop current_user, :any, from_context: :current_user
  prop uri, :string, from_context: :uri

  data loaded, :boolean, default: false
  data open, :boolean, default: false
  data notifications, :struct

  def update(%{new_notification: notification}, socket) do
    {:ok, on_new_notification(notification, socket)}
  end

  def update(%{notification_read: notification_ref}, socket) do
    {:ok, on_notification_read(notification_ref, socket)}
  end

  def update(%{all_notifications_read: true}, socket) do
    {:ok, on_all_notifications_read(socket)}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def update(assigns, socket) do
    current_user = Map.get(socket.assigns, :current_user)
    new_user = Map.get(assigns, :current_user)

    current_uri = Map.get(socket.assigns, :uri)
    new_uri = Map.get(assigns, :uri)

    old_parsed_uri =
      if current_uri do
        URI.parse(current_uri)
      else
        nil
      end

    parsed_uri = URI.parse(new_uri)

    if socket.assigns.loaded &&
         current_user &&
         new_user &&
         current_user.id == new_user.id &&
         current_uri &&
         %{
           old_parsed_uri
           | query:
               case Map.delete(URI.decode_query(old_parsed_uri.query || ""), "notification_ref") do
                 map when map == %{} ->
                   nil

                 other ->
                   URI.encode_query(other)
               end,
             fragment: nil
         } == %{parsed_uri | fragment: nil} do
      {:ok, socket |> assign(assigns)}
    else
      socket =
        if current_user && (!new_user || current_user.id != new_user.id) do
          Notifications.unsubscribe_from_notifications(current_user)
          socket |> assign(loaded: false)
        else
          socket
        end

      socket = socket |> assign(assigns)

      notifications =
        if new_user do
          Notifications.unsubscribe_from_notifications(new_user)
          Notifications.subscribe_to_notifications(new_user)

          Notifications.unread_notifications(new_user, 0)
        else
          nil
        end

      query = URI.decode_query(parsed_uri.query || "")
      notification_ref = Map.get(query, "notification_ref")
      query = Map.delete(query, "notification_ref")

      new_query =
        if Enum.empty?(query) do
          nil
        else
          URI.encode_query(query)
        end

      if new_user && notification_ref do
        Notifications.mark_notification_read(new_user, notification_ref)

        internal_patch_to(
          URI.to_string(%{
            parsed_uri
            | query: new_query,
              host: nil,
              authority: nil,
              userinfo: nil,
              scheme: nil,
              port: nil
          }),
          replace: true
        )
      end

      {:ok, socket |> assign(notifications: notifications, loaded: true)}
    end
  end

  def new_notification(component_id, notification) do
    send_update(__MODULE__, id: component_id, new_notification: notification)
  end

  defp on_new_notification(notification, socket) do
    notifications = socket.assigns.notifications

    if notifications do
      assign(socket,
        notifications: %{
          notifications
          | total_entries: notifications.total_entries + 1,
            entries: [notification | notifications.entries]
        }
      )
    else
      socket
    end
  end

  def notification_read(component_id, notification_ref) do
    send_update(__MODULE__, id: component_id, notification_read: notification_ref)
  end

  defp on_notification_read(notification_ref, socket) do
    notifications = socket.assigns.notifications

    if notifications do
      assign(socket,
        notifications: %{
          notifications
          | total_entries: notifications.total_entries - 1,
            entries: Enum.reject(notifications.entries, &(&1.ref == notification_ref))
        }
      )
    else
      socket
    end
  end

  def all_notifications_read(component_id) do
    send_update(__MODULE__, id: component_id, all_notifications_read: true)
  end

  def on_all_notifications_read(socket) do
    notifications = socket.assigns.notifications

    if notifications do
      assign(socket,
        notifications: %{
          notifications
          | total_entries: 0,
            entries: []
        }
      )
    else
      socket
    end
  end

  @impl true
  def handle_event("mark_all_as_read", _, socket) do
    Notifications.mark_all_as_read(socket.assigns.current_user)
    {:noreply, socket |> assign(open: false)}
  end

  @impl true
  def handle_event("toggle_menu", _, socket) do
    {:noreply, socket |> assign(open: !socket.assigns.open)}
  end

  @impl true
  def handle_event("close_menu", _, socket) do
    {:noreply, socket |> assign(open: false)}
  end

  defp annotated_url(%UserNotification{} = notification) do
    parsed = URI.parse(notification.url)

    query =
      parsed.query ||
        ""
        |> URI.decode_query(%{"notification_ref" => notification.ref})
        |> URI.encode_query()

    URI.to_string(%{parsed | query: query})
  end

  def render(assigns) do
    ~F"""
    <div class="relative" :on-click-away="close_menu">
      <div class="indicator">
        {#if @notifications && @notifications.total_entries > 0}
          <span class="indicator-item indicator-bottom indicator-start badge badge-primary">
            {#if @notifications.total_entries > 99}
              99+
            {#else}
              {@notifications.total_entries}
            {/if}
          </span>
        {/if}
        <button
          type="button"
          :on-click="toggle_menu"
          class="btn btn-circle btn-ghost"
          aria-label="Notifications"
        >
          <Icon name="bell" size="4" />
        </button>
      </div>
      {#if @open}
        <div class="absolute right-0 z-30 p-2 origin-top translate-x-px translate-y-px border divide-y-2 border-base-content border-opacity-10 menu rounded-box bg-base-300 w-80 divide-neutral-content divide-opacity-10 text-base-content">
          {#if !@notifications || Enum.empty?(@notifications.entries)}
            <div class="px-8 m-2">No notifications</div>
          {#else}
            <ul>
              <li>
                <button :on-click="mark_all_as_read" class="pl-10" type="button">
                  Mark All as Read
                </button>
              </li>
              <li class="menu-title">
                <hr>
              </li>
              {#for notification <- @notifications.entries}
                <li class="relative">
                  <LiveRedirect to={annotated_url(notification)}>
                    <div class="indicator">
                      {#if !notification.read}
                        <span class="cursor-default indicator-item indicator-middle indicator-start badge badge-xs badge-primary" />
                      {/if}
                      <div class="flex flex-col pl-6">
                        <div class="text-lg">{notification.title}</div>
                        <div class="text-xs">{notification.short_body}</div>
                      </div>
                    </div>
                  </LiveRedirect>
                </li>
              {/for}
            </ul>
          {/if}
        </div>
      {/if}
    </div>
    """
  end
end
