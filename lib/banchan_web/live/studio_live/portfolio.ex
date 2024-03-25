defmodule BanchanWeb.StudioLive.Portfolio do
  @moduledoc """
  Portfolio tab page for a studio.
  """
  use BanchanWeb, :live_view

  alias Banchan.Works

  alias Surface.Components.LiveRedirect

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.StudioLive.Components.StudioLayout

  alias BanchanWeb.Components.{Card, Icon, InfiniteScroll}

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
    <style>
      .portfolio-container {
      @apply flex flex-col p-4;
      }
      .portfolio-container ul {
      @apply gap-0 sm:gap-1 columns-2 sm:columns-3 md:columns-4;
      }
      .portfolio-container ul > li {
      @apply my-0 sm:mb-2 relative sm:hover:scale-105 sm:hover:z-10 cursor-pointer transition-all w-full;
      }
      .portfolio-container ul img {
      @apply w-full h-full object-cover;
      }
      .portfolio-container :deep(bc-card) {
      @apply h-full transition-all border-2 border-dashed rounded-lg opacity-50 hover:opacity-100 hover:bg-base-200;
      }
      .portfolio-container :deep(bc-card) :deep(.default-slot) {
      @apply items-center w-full gap-2 p-4 my-auto h-fit;
      }
      .portfolio-container :deep(bc-card) :deep(.default-slot) :deep(:nth-child(1)) {
      @apply text-3xl;
      }
      .portfolio-container :deep(bc-card) :deep(.default-slot) :deep(:nth-child(2)) {
      @apply text-sm text-center;
      }
      .portfolio-container :deep(bc-icon) {
      @apply flex flex-col items-center justify-center h-full;
      }
      .portfolio-container :deep(bc-icon) :deep(span) {
      @apply text-pretty break-words m-2;
      }
    </style>
    <StudioLayout flashes={@flash} id="studio-layout" studio={@studio} tab={:portfolio}>
      <div class="portfolio-container" data-order-seed={@order_seed}>
        <ul>
          {#if @current_user_member?}
            <li>
              <LiveRedirect to={~p"/studios/#{@studio.handle}/works/new"}>
                <Card>
                  <span>New Work</span>
                  <span>Create a new custom work for your portfolio.</span>
                </Card>
              </LiveRedirect>
            </li>
          {/if}
          {#for work <- @works}
            <li>
              <LiveRedirect to={~p"/studios/#{@studio.handle}/works/#{work.public_id}"}>
                {#if Works.first_previewable_upload(work)}
                  <img
                    src={~p"/studios/#{@studio.handle}/works/#{work.public_id}/upload/#{Works.first_previewable_upload(work).upload_id}/preview"}
                    alt={work.title}
                  />
                {#else}
                  <Icon name="file-up" size={32} label={Enum.at(work.uploads, 0).upload.name}>
                    <span>{Enum.at(work.uploads, 0).upload.name}</span>
                  </Icon>
                {/if}
              </LiveRedirect>
            </li>
          {#else}
            Nothing to see here
          {/for}
        </ul>
        <InfiniteScroll id="works-infinite-scroll" page={@works.page_number} load_more="load_more" />
      </div>
    </StudioLayout>
    """
  end
end
