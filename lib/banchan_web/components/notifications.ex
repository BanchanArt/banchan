defmodule BanchanWeb.Components.Notifications do
  @moduledoc """
  Notification display.
  """
  use BanchanWeb, :live_component

  alias Banchan.Notifications
  alias Banchan.Notifications.UserNotification

  prop current_user, :any, required: true
  prop uri, :string, required: true

  data loaded, :boolean, default: false
  data open, :boolean, default: false
  data notifications, :struct

  def update(assigns, socket) do
    current_user = Map.get(socket.assigns, :current_user)
    new_user = Map.get(assigns, :current_user)

    current_uri = Map.get(socket.assigns, :uri)
    new_uri = Map.get(assigns, :uri)

    if socket.assigns.loaded &&
         current_user &&
         new_user &&
         current_user.id == new_user.id &&
         current_uri ==
           new_uri do
      socket = socket |> assign(assigns)
      {:ok, socket}
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
        if socket.assigns.current_user do
          Notifications.subscribe_to_notifications(socket.assigns.current_user)

          Notifications.user_notifications(socket.assigns.current_user, 0)
        else
          nil
        end

      parsed_uri = URI.parse(new_uri)
      query = URI.decode_query(parsed_uri.query || "")
      notification_ref = Map.get(query, "notification_ref")

      if new_user && notification_ref do
        Notifications.mark_notification_read(new_user, notification_ref)

        query = Map.delete(query, "notification_ref")

        new_query =
          if Enum.empty?(query) do
            nil
          else
            URI.encode_query(query)
          end

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

  def handle_info(%{event: "new_notification", payload: notification}, socket) do
    notifications = socket.assigns.notifications

    {:noreply,
     assign(socket,
       notifications: %{
         notifications
         | total_entries: notifications.total_entries + 1,
           entries: [notification | Enum.drop(notifications.entries, -1)]
       }
     )}
  end

  def handle_info(%{event: "notification_read", payload: notification_ref}, socket) do
    notifications = socket.assigns.notifications

    if notifications do
      {:noreply,
       assign(socket,
         notifications: %{
           notifications
           | total_entries: notifications.total_entries - 1,
             entries: Enum.reject(notifications.entries, &(&1.ref == notification_ref))
         }
       )}
    else
      {:noreply, socket}
    end
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
          <span class="indicator-item indicator-bottom indicator-right badge badge-secondary">
            {@notifications.total_entries}
          </span>
        {/if}
        <button type="button" :on-click="toggle_menu" class="btn btn-circle">
          <i class="fas fa-bell" />
        </button>
      </div>
      {#if @open}
        <div class="translate-x-px translate-y-px origin-top right-0 absolute menu rounded-box shadow-2xl bg-base-300 p-2 w-80 z-50 divide-y text-base-content">
          <ul>
            {#for notification <- @notifications.entries}
              <li class="relative">
                <a href={annotated_url(notification)} class="pr-8">
                  <div class="indicator">
                    {#if !notification.read}
                      <span class="indicator-item indicator-middle indicator-start badge badge-xs badge-secondary" />
                    {/if}
                    <div class="pl-6 flex flex-col">
                      <div class="text-lg">{notification.title}</div>
                      <div class="text-xs">{notification.body}</div>
                    </div>
                  </div>
                </a>
                <button type="button" class="btn btn-ghost btn-circle absolute right-0 inset-y-0 h-full">
                  <i class="fas fa-ellipsis-v" />
                </button>
              </li>
            {/for}
          </ul>
        </div>
      {/if}
    </div>
    """
  end
end
