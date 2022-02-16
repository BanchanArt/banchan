defmodule BanchanWeb.StudioLive.Commissions.Show do
  @moduledoc """
  Subpage for commissions themselves. This is where the good stuff happens.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions
  alias Banchan.Commissions.LineItem

  alias BanchanWeb.StudioLive.Components.Commissions.{
    CommentBox,
    InvoiceForm,
    Status,
    SummaryEditor,
    Timeline
  }

  alias BanchanWeb.StudioLive.Components.StudioLayout

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

    custom_changeset =
      if socket.assigns.current_user_member? do
        %LineItem{} |> LineItem.custom_changeset(%{})
      else
        nil
      end

    {:ok,
     socket
     |> assign(commission: commission, custom_changeset: custom_changeset, open_custom: false)}
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

  def handle_info(%{event: "line_items_changed", payload: line_items}, socket) do
    {:noreply, assign(socket, commission: %{socket.assigns.commission | line_items: line_items})}
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
  def handle_event("update-status", %{"status" => [new_status]}, socket) do
    comm = %{socket.assigns.commission | tos_ok: true}

    {:ok, {commission, _events}} =
      Commissions.update_status(socket.assigns.current_user, comm, new_status)

    {:noreply, socket |> assign(commission: commission)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:shop}
    >
      <div>
        <h1 class="text-3xl p-4">{@commission.title}</h1>
        <hr>
        <div class="commission grid gap-4">
          <div class="col-span-10">
            <div class="p-4">
              <Timeline
                uri={@uri}
                studio={@studio}
                commission={@commission}
                current_user={@current_user}
                current_user_member?={@current_user_member?}
              />
            </div>
            <div class="p-4">
              <CommentBox id="comment-box" commission={@commission} actor={@current_user} />
            </div>
          </div>
          <div class="col-span-2 col-end-13 p-6">
            <div id="sidebar">
              <div class="block sidebar-box">
                <SummaryEditor
                  id="summary-editor"
                  current_user={@current_user}
                  commission={@commission}
                  allow_edits={@current_user_member?}
                />
              </div>
              <div class="block sidebar-box">
                <Status commission={@commission} editable={@current_user_member?} change="update-status" />
              </div>
              {#if @current_user_member?}
                <div class="block sidebar-box">
                  <InvoiceForm id="invoice" current_user={@current_user} commission={@commission} />
                </div>
              {/if}
            </div>
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
