defmodule BanchanWeb.DiscoverLive.Components.Studios do
  @moduledoc """
  Studios result listing for the Discover page.
  """
  use BanchanWeb, :live_component

  alias Banchan.Studios

  alias BanchanWeb.Components.{InfiniteScroll, StudioCard}

  prop current_user, :struct
  prop query, :string
  prop order_by, :atom, default: :homepage
  prop page_size, :integer, default: 24
  prop infinite, :boolean, default: true

  data studios, :list

  def update(assigns, socket) do
    socket = socket |> assign(assigns)
    {:ok, socket |> assign(studios: list_studios(socket))}
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

  defp list_studios(socket, page \\ 1) do
    Studios.list_studios(
      current_user: socket.assigns.current_user,
      order_by: socket.assigns.order_by || :homepage,
      include_pending: false,
      query: socket.assigns.query,
      page_size: socket.assigns.page_size,
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
    <discover-studios>
      {#if Enum.empty?(@studios)}
        <div class="text-2xl">No Results</div>
      {#else}
        <div class="studio-list grid grid-cols-1 sm:gap-2 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 auto-rows-fr">
          {#for studio <- @studios}
            <StudioCard studio={studio} />
          {/for}
        </div>
        {#if @infinite}
          <InfiniteScroll id="studios-infinite-scroll" page={@studios.page_number} load_more="load_more" />
        {/if}
      {/if}
    </discover-studios>
    """
  end
end
