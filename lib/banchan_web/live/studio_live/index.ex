defmodule BanchanWeb.StudioLive.Index do
  @moduledoc """
  Listing of studios belonging to the current user
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.Select

  alias BanchanWeb.Components.{InfiniteScroll, Layout, StudioCard}

  @impl true
  def mount(_params, _session, socket) do
    socket = socket |> assign(order_by: :featured)
    {:ok, socket |> assign(studios: list_studios(socket))}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.studios.total_entries >
         socket.assigns.studios.page_number * socket.assigns.studios.page_size do
      {:noreply, fetch(socket.assigns.studios.page_number + 1, socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change_sort", %{"sort_by" => %{"sort_by" => sort_by}}, socket) do
    sort_by = String.to_existing_atom(sort_by)
    socket = socket |> assign(order_by: sort_by)
    socket = socket |> assign(studios: list_studios(socket, 1))
    {:noreply, socket}
  end

  defp list_studios(socket, page \\ 1) do
    Studios.list_studios(
      order_by: socket.assigns.order_by,
      page_size: 24,
      page: page
    )
  end

  defp fetch(page, %{assigns: %{studios: studios}} = socket) do
    socket
    |> assign(
      :studios,
      %{
        studios
        | page_number: page,
          entries: studios.entries ++ list_studios(socket, page).entries
      }
    )
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <div class="flex flex-row sticky items-end">
        <h1 class="text-3xl grow">Studios</h1>
        <Form for={:sort_by} change="change_sort">
          <Select
            name={:sort_by}
            show_label={false}
            options={
              Featured: :featured,
              Newest: :newest,
              Earliest: :oldest,
              Followers: :followers
            }
          />
        </Form>
      </div>
      <div class="divider" />
      <div class="studio-list grid grid-cols-1 sm:gap-2 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 auto-rows-fr">
        {#for studio <- @studios}
          <StudioCard studio={studio} />
        {/for}
      </div>
      <InfiniteScroll id="studios-infinite-scroll" page={@studios.page_number} load_more="load_more" />
    </Layout>
    """
  end
end
