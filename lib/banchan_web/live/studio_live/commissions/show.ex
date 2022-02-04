defmodule BanchanWeb.StudioLive.Commissions.Show do
  @moduledoc """
  Subpage for commissions themselves. This is where the good stuff happens.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.StudioLive.Components.Commissions.{
    Attachments,
    CommentBox,
    Status,
    Summary,
    Timeline
  }

  alias BanchanWeb.StudioLive.Components.StudioLayout

  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(%{"commission_id" => commission_id} = params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, false)

    commission =
      Commissions.get_commission!(
        socket.assigns.studio,
        commission_id,
        socket.assigns.current_user,
        socket.assigns.current_user_member?
      )

    BanchanWeb.Endpoint.subscribe("commission:#{commission.public_id}")
    {:ok, assign(socket, commission: commission)}
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

  @impl true
  def handle_event("remove_item", %{"value" => idx}, socket) do
    # TODO: this should go through a consent workflow.
    {idx, ""} = Integer.parse(idx)
    line_item = Enum.at(socket.assigns.commission.line_items, idx)
    new_items = List.delete_at(socket.assigns.commission.line_items, idx)

    if line_item && !line_item.sticky do
      {:noreply, assign(socket, commission: %{socket.assigns.commission | line_items: new_items})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update-status", %{"status" => [new_status]}, socket) do
    comm = %{socket.assigns.commission | tos_ok: true}

    {:ok, {commission, events}} =
      Commissions.update_status(socket.assigns.current_user, comm, new_status)

    BanchanWeb.Endpoint.broadcast!(
      "commission:#{comm.public_id}",
      "new_status",
      commission.status
    )

    BanchanWeb.Endpoint.broadcast!("commission:#{comm.public_id}", "new_events", events)

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
        <h1 class="text-3xl">{@commission.title}</h1>
        <hr>
        <div class="commission grid gap-4">
          <div class="col-span-10">
            <Timeline id="timeline" commission={@commission} />
            <hr>
            <CommentBox id="comment-box" commission={@commission} actor={@current_user} />
          </div>
          <div class="col-span-2 col-end-13 p-6">
            <div id="sidebar">
              <div class="block sidebar-box">
                <Summary
                  line_items={@commission.line_items}
                  offering={@commission.offering}
                  add_item="add_item"
                  remove_item="remove_item"
                />
              </div>
              <div class="block sidebar-box">
                <Status commission={@commission} editable={@current_user_member?} change="update-status" />
              </div>
              <div class="block sidebar-box">
                <Attachments id="commission-attachments" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
