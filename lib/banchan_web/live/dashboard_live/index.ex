defmodule BanchanWeb.DashboardLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.DashboardLive.Components.{TableLink, TableRow}

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
       :rows,
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
      <h1 class="text-2xl">Dashboard</h1>
      <h2 class="text-xl">Commissions</h2>
      <div class="overflow-x-auto">
        <table class="table w-full table-compact">
          <thead>
            <tr>
              <th><TableLink field={:client_handle} params={@params}>Client</TableLink></th>
              <th><TableLink field={:studio_handle} params={@params}>Studio</TableLink></th>
              <th><TableLink field={:title} params={@params}>Commission</TableLink></th>
              <th><TableLink field={:status} params={@params}>Status</TableLink></th>
              <th />
            </tr>
          </thead>
          <tbody>
            {#for row <- @rows}
              <TableRow data={row} />
            {/for}
          </tbody>
        </table>
      </div>
    </Layout>
    """
  end
end
