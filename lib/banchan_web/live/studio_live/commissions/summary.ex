defmodule BanchanWeb.StudioLive.Commissions.Summary do
  @moduledoc """
  Commission summary tab page.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.StudioLive.Components.Commissions.SummaryEditor

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

  def handle_info(%{event: "line_items_changed", payload: line_items}, socket) do
    {:noreply, assign(socket, commission: %{socket.assigns.commission | line_items: line_items})}
  end

  def handle_info(%{event: "new_status", payload: status}, socket) do
    commission = %{socket.assigns.commission | status: status}
    {:noreply, assign(socket, commission: commission)}
  end

  def handle_info(_, socket) do
    # Ignore other events. We don't care about timeline items, for example.
    {:noreply, socket}
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
      tab={:summary}
    >
      <div class="h-20 border-2 border-neutral rounded-box p-2">
        {!-- #TODO --}
        ALSO: Current $amount in escrow?
        ALSO ALSO: Move this to the side on md+ screens!
      </div>
      <SummaryEditor
        id="summary-editor"
        current_user={@current_user}
        commission={@commission}
        allow_edits={@current_user_member?}
      />
    </CommissionLayout>
    """
  end
end
