defmodule BanchanWeb.DiscoverLive.Components.Works do
  @moduledoc """
  Works result listing for the Discover page.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LivePatch

  alias Banchan.Works

  alias BanchanWeb.Components.{InfiniteScroll, WorkGallery}

  prop(current_user, :struct, from_context: :current_user)
  prop(query, :string)
  prop(order_by, :atom, default: :featured)
  prop(order_seed, :number)
  prop(page_size, :integer, default: 24)
  prop(infinite, :boolean, default: true)
  prop(suggest_offerings, :boolean, default: false)

  data(works, :list)

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    {:ok, socket |> assign(works: list_works(socket))}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.works.total_entries >
         socket.assigns.works.page_number * socket.assigns.works.page_size do
      {:noreply, fetch_results(socket.assigns.works.page_number + 1, socket)}
    else
      {:noreply, socket}
    end
  end

  defp list_works(socket, page \\ 1) do
    Works.list_works(
      current_user: socket.assigns.current_user,
      order_by: socket.assigns.order_by || :featured,
      query: socket.assigns.query,
      page_size: socket.assigns.page_size,
      page: page,
      order_seed: socket.assigns.order_seed
    )
  end

  defp fetch_results(page, %{assigns: %{works: works}} = socket) do
    socket
    |> assign(
      :works,
      %{
        works
        | page_number: page,
          entries: works.entries ++ list_works(socket, page).entries
      }
    )
  end

  @impl true
  def render(assigns) do
    params =
      if assigns.query && assigns.query != "" do
        %{q: assigns.query}
      else
        %{}
      end

    ~F"""
    <discover-works data-order-seed={@order_seed}>
      {#if Enum.empty?(@works)}
        <div class="no-results">
          <span>No Results</span>
          {#if @suggest_offerings}
            <LivePatch
              class="suggestion-link"
              to={Routes.discover_index_path(Endpoint, :index, "offerings", params)}
            >Search Offerings instead.</LivePatch>
          {/if}
        </div>
      {#else}
        <WorkGallery works={@works} />
        {#if @infinite}
          <InfiniteScroll id="studios-infinite-scroll" page={@works.page_number} load_more="load_more" />
        {/if}
      {/if}
    </discover-works>
    """
  end
end
