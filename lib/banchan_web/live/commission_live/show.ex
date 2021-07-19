defmodule BanchanWeb.CommissionLive.Show do
  @moduledoc """
  Main page for viewing and interacting with a Commission
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions
  alias Banchan.Commissions.Commission

  alias BanchanWeb.Components.Commissions.{
    Attachments,
    MessageBox,
    Status,
    Summary,
    Timeline,
    Transactions
  }

  alias BanchanWeb.Components.Layout

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => _id}, _, socket) do
    {:noreply,
     socket
     |> assign(commission: %Commission{})}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="title">Two-character drawing of me and my gf's FFXIV OCs</h1>
      <h2 class="subtitle"><strong>{@current_user.handle}</strong> requested this commission 3 days ago.</h2>
      <hr>
      <div class="commission columns">
        <div class="column is-three-quarters">
          <Timeline id="timeline" current_user={@current_user} commission={@commission} />
          <hr>
          <MessageBox id="reply-box" new_message="new-message" />
        </div>
        <div class="column is-one-quarter">
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
    </Layout>
    """
  end

  @impl true
  def handle_event("update-status", %{"status" => [new_status]}, socket) do
    comm = socket.assigns.commission
    {:ok, commission} = Commissions.update_commission(comm, %{title: comm.title, status: new_status})
    {:noreply, socket |> assign(commission: commission)}
  end

  @impl true
  def handle_event("new-message", %{"message" => message}, socket) do
    IO.inspect(message)
    {:noreply, socket}
  end
end
