defmodule BanchanWeb.StudioLive.Commission do
  @moduledoc """
  Subpage for commissions themselves. This is where the good stuff happens.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions
  alias Banchan.Commissions.Commission

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
  def mount(params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, false)
    {:ok, assign(socket, commission: %Commission{})}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout current_user={@current_user} flashes={@flash} studio={@studio} current_user_member?={@current_user_member?} tab={:shop}>
      <div>
        <h1 class="text-3xl">Two-character drawing of me and my gf's FFXIV OCs</h1>
        <h2 class="text-lg"><strong>{@current_user.handle}</strong> requested this commission 3 days ago.</h2>
        <hr>
        <div class="commission grid gap-4">
          <div class="col-span-10">
            <Timeline id="timeline" current_user={@current_user} commission={@commission} />
            <hr>
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
