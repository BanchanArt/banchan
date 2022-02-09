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

    {:ok,
     socket
     |> assign(commission: commission)}
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

  @impl true
  def handle_event("add_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)

    commission = socket.assigns.commission

    option =
      if commission.offering do
        {:ok, option} = Enum.fetch(commission.offering.options, idx)
        option
      else
        %{
          # TODO: fill this out?
        }
      end

    if !socket.assigns.current_user_member? ||
         (!option.multiple && Enum.any?(commission.line_items, &(&1.option.id == option.id))) do
      # Deny the change. This shouldn't happen unless there's a bug, or
      # someone is trying to send us Shenanigans data.
      {:noreply, socket}
    else
      {:ok, {commission, events}} =
        Commissions.add_line_item(socket.assigns.current_user, commission, option)

      BanchanWeb.Endpoint.broadcast_from!(
        self(),
        "commission:#{commission.public_id}",
        "line_items_changed",
        commission.line_items
      )

      BanchanWeb.Endpoint.broadcast!("commission:#{commission.public_id}", "new_events", events)

      {:noreply, assign(socket, commission: commission)}
    end
  end

  def handle_event("remove_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)
    line_item = Enum.at(socket.assigns.commission.line_items, idx)

    if socket.assigns.current_user_member? && line_item && !line_item.sticky do
      {:ok, {commission, events}} =
        Commissions.remove_line_item(
          socket.assigns.current_user,
          socket.assigns.commission,
          line_item
        )

      BanchanWeb.Endpoint.broadcast_from!(
        self(),
        "commission:#{commission.public_id}",
        "line_items_changed",
        commission.line_items
      )

      BanchanWeb.Endpoint.broadcast!("commission:#{commission.public_id}", "new_events", events)

      {:noreply, assign(socket, commission: commission)}
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
            <div class="p-4">
              <Timeline uri={@uri} studio={@studio} commission={@commission} current_user={@current_user} current_user_member?={@current_user_member?} />
            </div>
            <div class="p4">
              <CommentBox id="comment-box" commission={@commission} actor={@current_user} />
            </div>
          </div>
          <div class="col-span-2 col-end-13 p-6">
            <div id="sidebar">
              <div class="block sidebar-box">
                <Summary
                  line_items={@commission.line_items}
                  offering={@commission.offering}
                  allow_edits={@current_user_member?}
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
