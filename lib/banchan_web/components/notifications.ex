defmodule BanchanWeb.Components.Notifications do
  @moduledoc """
  Notification display.
  """
  use BanchanWeb, :live_component

  alias Banchan.Notifications

  prop current_user, :any, required: true

  data loaded, :boolean, default: false
  data open, :boolean, default: false
  data notifications, :struct

  def update(assigns, socket) do
    current_user = Map.get(socket.assigns, :current_user)
    new_user = Map.get(assigns, :current_user)

    if socket.assigns.loaded &&
         current_user &&
         new_user &&
         current_user.id == new_user.id do
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

      {:ok, socket |> assign(notifications: notifications, loaded: true)}
    end
  end

  def handle_info(%{event: "new_notification", payload: notification}, socket) do
    notifications = socket.asigns.notifications

    {:noreply,
     assign(socket,
       notifications: %{
         notifications
         | total_entries: notifications.total_entries + 1,
           entries: [notification | Enum.drop(notifications.entries, -1)]
       }
     )}
  end

  @impl true
  def handle_event("toggle_menu", _, socket) do
    {:noreply, socket |> assign(open: !socket.assigns.open)}
  end

  @impl true
  def handle_event("close_menu", _, socket) do
    {:noreply, socket |> assign(open: false)}
  end

  @impl true
  def handle_event("nothing", _, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="relative">
      <div class="indicator">
        {#if @notifications && @notifications.total_entries > 0}
          <span class="indicator-item indicator-bottom indicator-right badge badge-secondary">
            {@notifications.total_entries}
          </span>
        {/if}
        <button type="button" :on-click-away="close_menu" :on-click="toggle_menu" class="btn btn-circle">
          <i class="fas fa-bell" />
        </button>
      </div>
      {#if @open}
        <div class="translate-x-px translate-y-px origin-top right-0 absolute menu rounded-box shadow-2xl bg-base-300 p-2 w-80 z-50 divide-y text-base-content">
          <ul>
            {#for notification <- @notifications.entries}
              <li class="relative">
                <a class="flex flex-row" href={notification.url}>
                  <div class="indicator basis-10/12">
                    {#if !notification.read}
                      <span class="indicator-item indicator-middle indicator-start badge badge-xs badge-secondary" />
                    {/if}
                    <div class="pl-6 flex flex-col">
                      <div class="text-lg">{notification.title}</div>
                      <div class="text-xs">{notification.body}</div>
                    </div>
                  </div>
                  <button type="button" :on-click="nothing" class="btn btn-ghost basis-2/12">
                    <i class="fas fa-ellipsis-v" />
                  </button>
                </a>
              </li>
            {/for}
          </ul>
        </div>
      {/if}
    </div>
    """
  end
end
