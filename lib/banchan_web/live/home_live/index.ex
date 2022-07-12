defmodule BanchanWeb.HomeLive do
  @moduledoc """
  Banchan Homepage
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings
  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Carousel, Layout, StudioCard}
  alias BanchanWeb.StudioLive.Components.OfferingCard

  @impl true
  def mount(_params, _session, socket) do
    offerings =
      Offerings.list_offerings(
        current_user: socket.assigns.current_user,
        page_size: 16,
        order_by: :featured
      )

    featured_studios =
      Studios.list_studios(
        page_size: 10,
        order_by: :featured
      )

    studios =
      Studios.list_studios(
        page_size: 4,
        order_by: :homepage
      )

    {:ok,
     assign(socket, offerings: offerings, studios: studios, featured_studios: featured_studios)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <:hero>
        <div id="carousel-handler" class="flex-grow">
          <Carousel
            id="studio-carousel"
            label="Featured Studios"
            class="rounded-b-xl aspect-header-image h-full w-full"
          >
            {#for studio <- @featured_studios.entries}
              <Carousel.Slide class="carousel-item w-full aspect-header-image relative">
                <LiveRedirect
                  class="w-full h-full aspect-header-image"
                  to={Routes.studio_shop_path(Endpoint, :show, studio.handle)}
                >
                  <img
                    class="object-cover aspect-header-image w-full"
                    src={Routes.public_image_path(Endpoint, :image, studio.header_img_id || studio.card_img_id)}
                  />
                </LiveRedirect>
                <div class="absolute top-2 left-2 md:top-6 md:left-6 text-3xl sm:text-3xl md:text-6xl font-bold text-white">
                  {studio.name}
                </div>
              </Carousel.Slide>
            {/for}
          </Carousel>
        </div>
      </:hero>
      <div class="flex flex-col">
        <div class="homepage-offerings">
          <div class="px-2 flex flex-row items-end">
            <div class="text-xl grow">
              Selected Offerings
            </div>
            <div class="text-md">
              <LiveRedirect class="hover:link text-primary" to={Routes.offering_index_path(Endpoint, :index)}>View All</LiveRedirect>
            </div>
          </div>
          <div class="divider" />
          <div class="sm:px-2 flex flex-col gap-4">
            <div class="grid grid-cols-2 sm:gap-2 md:grid-cols-4 auto-rows-fr">
              {#for {offering, idx} <- Enum.with_index(@offerings.entries)}
                <OfferingCard id={"offering-#{idx}"} current_user={@current_user} offering={offering} />
              {/for}
            </div>
          </div>
        </div>
        <div class="featured-studios pt-10">
          <div class="px-2 flex flex-row items-end">
            <div class="text-xl grow">
              Selected Studios
            </div>
            <div class="text-md">
              <LiveRedirect class="hover:link text-primary" to={Routes.studio_index_path(Endpoint, :index)}>View All</LiveRedirect>
            </div>
          </div>
          <div class="divider" />
          <div class="sm:px-2 flex flex-col gap-4">
            <div class="grid grid-cols-2 sm:gap-2 md:grid-cols-4 auto-rows-fr">
              {#for studio <- @studios.entries}
                <StudioCard studio={studio} />
              {/for}
            </div>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
