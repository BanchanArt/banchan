defmodule BanchanWeb.DashboardLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.DashboardLive.Components.{DashboardPaginator, DashboardResult}

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
       Commissions.list_commission_data_for_dashboard(
         socket.assigns.current_user,
         page(params),
         sort(params)
       )
     )}
  end

  defp sort(%{"by" => field, "dir" => direction}) when direction in ~w(asc desc) do
    {String.to_existing_atom(direction), String.to_existing_atom(field)}
  end

  defp sort(_other) do
    {:asc, :id}
  end

  defp page(%{"page" => page}) do
    {page, ""} = Integer.parse(page)
    page
  end

  defp page(_other) do
    1
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <section class="shadow bg-base-200 text-base-content min-h-full">
        <div class="p-6">
          <h1 class="text-2xl">Commission Dashboard</h1>
          <ul class="divide-y">
            {#for result <- @results.entries}
              <li class="bg-base-100 px-4 py-2 shadow">
                <DashboardResult result={result}/>
              </li>
              {#else}
              <p>You currently have no open commissions. Check back in later!</p>
            {/for}
          </ul>
          <DashboardPaginator page={@results} />
        </div>
      </section>
    </Layout>
    """
  end
end
