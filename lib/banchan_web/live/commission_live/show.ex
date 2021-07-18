defmodule BanchanWeb.CommissionLive.Show do
  @moduledoc """
  Main page for viewing and interacting with a Commission
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions.Commission
  alias BanchanWeb.Components.Commissions.{Attachments, MessageBox, Status, Summary, Timeline, Transactions}
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
     |> assign(commission: %Commission{}, changeset: Commission.changeset(%Commission{}, %{}))}
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
          <MessageBox id="message-box" changeset={@changeset} />
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
              <Status id="commission-status" />
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
end
