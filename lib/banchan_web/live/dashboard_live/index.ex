defmodule BanchanWeb.DashboardLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.DashboardLive.Components.DashboardResult

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(
       :results,
       Commissions.list_commission_data_for_dashboard(socket.assigns.current_user, sort(params))
     )}
  end

  defp sort(%{"by" => field, "dir" => direction}) when direction in ~w(asc desc) do
    {String.to_existing_atom(direction), String.to_existing_atom(field)}
  end

  defp sort(_other) do
    {:asc, :id}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Commission Dashboard</h1>
      <ul class="divide-y">
        {#for result <- @results}
          <li>
            <DashboardResult result={result} />
          </li>
        {/for}
      </ul>
    </Layout>
    """
  end
end
