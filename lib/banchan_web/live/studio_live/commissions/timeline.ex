defmodule BanchanWeb.StudioLive.Commissions.Timeline do
  @moduledoc """
  Subpage for commissions themselves. This is where the good stuff happens.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.StudioLive.Components.Commissions.{
    CommentBox,
    Timeline
  }

  alias BanchanWeb.StudioLive.Components.Commissions.CommissionLayout

  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(%{"commission_id" => commission_id} = params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, false, false)

    commission =
      Commissions.get_commission!(
        socket.assigns.studio,
        commission_id,
        socket.assigns.current_user,
        socket.assigns.current_user_member?
      )

    Commissions.subscribe_to_commission_events(commission)

    {:ok, socket |> assign(commission: commission)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_info(%{event: "new_events", payload: events}, socket) do
    events = socket.assigns.commission.events ++ events
    events = events |> Enum.sort_by(& &1.inserted_at)
    commission = %{socket.assigns.commission | events: events}
    {:noreply, assign(socket, commission: commission)}
  end

  def handle_info(%{event: "new_status", payload: status}, socket) do
    commission = %{socket.assigns.commission | status: status}
    {:noreply, assign(socket, commission: commission)}
  end

  def handle_info(%{event: "event_updated", payload: event}, socket) do
    events =
      socket.assigns.commission.events
      |> Enum.map(fn ev ->
        if ev.id == event.id do
          event
        else
          ev
        end
      end)

    commission = %{socket.assigns.commission | events: events}
    {:noreply, assign(socket, commission: commission)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <CommissionLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      commission={@commission}
      tab={:timeline}
    >
      <div class="p-2">
        <Timeline
          uri={@uri}
          studio={@studio}
          commission={@commission}
          current_user={@current_user}
          current_user_member?={@current_user_member?}
        />
        <CommentBox id="comment-box" commission={@commission} actor={@current_user} />
      </div>
    </CommissionLayout>
    """
  end
end