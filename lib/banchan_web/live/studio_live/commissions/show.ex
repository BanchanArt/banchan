defmodule BanchanWeb.StudioLive.Commissions.Show do
  @moduledoc """
  Subpage for commissions themselves. This is where the good stuff happens.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.StudioLive.Components.Commissions.{
    ActionBox,
    CommentBox,
    CommissionLayout,
    SummaryEditor,
    Timeline
  }

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

  def handle_info(%{event: "line_items_changed", payload: line_items}, socket) do
    {:noreply,
     socket |> assign(commission: %{socket.assigns.commission | line_items: line_items})}
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
      <div class="flex flex-col md:grid md:grid-cols-3 gap-4">
        <div class="flex flex-col md:order-2">
          <div class="h-20 border-2 border-neutral rounded-box p-2 mb-4">
            {!-- #TODO --}
            Latest draft goes here
          </div>
          {!-- # TODO: Show current amount in escrow --}
          <SummaryEditor
            id="summary-editor"
            current_user={@current_user}
            commission={@commission}
            allow_edits={@current_user_member?}
          />
        </div>
        <div class="divider md:hidden" />
        <div class="flex flex-col md:col-span-2 md:order-1">
          <Timeline
            uri={@uri}
            studio={@studio}
            commission={@commission}
            current_user={@current_user}
            current_user_member?={@current_user_member?}
          />
          <div class="divider" />
          <div class="flex flex-col gap-4">
            <ActionBox
              id="action-box"
              commission={@commission}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
            />
            <CommentBox
              id="comment-box"
              commission={@commission}
              actor={@current_user}
              current_user_member?={@current_user_member?}
            />
          </div>
        </div>
      </div>
    </CommissionLayout>
    """
  end
end
