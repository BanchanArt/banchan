defmodule BanchanWeb.DashboardLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias BanchanWeb.Components.Layout

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Dashboard</h1> <h2 class="text-xl">Commissions</h2> <ul>
        <li>Thing 1</li> <li>Thing 2</li>
      </ul>
    </Layout>
    """
  end
end
