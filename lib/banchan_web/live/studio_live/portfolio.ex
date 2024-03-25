defmodule BanchanWeb.StudioLive.Portfolio do
  @moduledoc """
  Portfolio tab page for a studio.
  """
  use BanchanWeb, :live_view

  alias Banchan.Works

  alias Surface.Components.LiveRedirect

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.StudioLive.Components.StudioLayout

  alias BanchanWeb.Components.{Card, InfiniteScroll, WorkGallery}

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)

    socket =
      socket
      |> assign(
        page_size: 24,
        order_by: :featured,
        query: nil,
        infinite: true,
        order_seed: get_connect_params(socket)["order_seed"] || Prime.generate(16)
      )

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
      studio: socket.assigns.studio,
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
    # params =
    #   if assigns.query && assigns.query != "" do
    #     %{q: assigns.query}
    #   else
    #     %{}
    #   end

    ~F"""
    <StudioLayout flashes={@flash} id="studio-layout" studio={@studio} tab={:portfolio}>
      <div class="portfolio-container" data-order-seed={@order_seed}>
        <WorkGallery works={@works}>
          {#if @current_user_member?}
            <LiveRedirect to={~p"/studios/#{@studio.handle}/works/new"}>
              <Card>
                <span>New Work</span>
                <span>Create a new custom work for your portfolio.</span>
              </Card>
            </LiveRedirect>
          {/if}
        </WorkGallery>
        <InfiniteScroll id="works-infinite-scroll" page={@works.page_number} load_more="load_more" />
      </div>
    </StudioLayout>
    """
  end
end
