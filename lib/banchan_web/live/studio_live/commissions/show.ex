defmodule BanchanWeb.StudioLive.Commissions.Show do
  @moduledoc """
  Subpage for commissions themselves. This is where the good stuff happens.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.StudioLive.Components.StudioLayout

  alias BanchanWeb.StudioLive.Components.Commissions.{
    Attachments,
    MessageBox,
    Status,
    Summary,
    Timeline,
    Transactions
  }

  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(%{"commission_id" => commission_id} = params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, false)
    commission = Commissions.get_commission!(socket.assigns.studio, commission_id)
    {:ok, assign(socket, commission: commission)}
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
        <hr />
        <div class="commission grid gap-4">
          <div class="col-span-10">
            <Timeline id="timeline" current_user={@current_user} commission={@commission} />
            <hr />
            <MessageBox id="reply-box" new_message="new-message" />
          </div>
          <div class="col-span-2 col-end-13 shadow-lg p-6">
            <div id="sidebar">
              <div class="block sidebar-box">
                <Summary id="commission-summary" />
              </div>
              <div class="block sidebar-box">
                <Transactions id="commission-transactions" />
              </div>
              <div class="block sidebar-box">
                <Status commission={@commission} change="update-status" />
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

  @impl true
  def handle_event("update-status", %{"status" => [new_status]}, socket) do
    comm = socket.assigns.commission

    {:ok, commission} =
      Commissions.update_commission(comm, %{title: comm.title, status: new_status})

    {:noreply, socket |> assign(commission: commission)}
  end
end
