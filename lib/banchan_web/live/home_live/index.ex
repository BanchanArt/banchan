defmodule BanchanWeb.HomeLive do
  @moduledoc """
  Banchan Homepage
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings
  alias Banchan.Studios

  alias Surface.Components.{Form, LiveRedirect}
  alias Surface.Components.Form.{Field, Submit}
  alias Surface.Components.Form.TextInput

  alias BanchanWeb.Components.{Carousel, Layout, StudioCard, Tag}
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

    categories = [
      "fanart",
      "book art",
      "OC art",
      "vtuber model",
      "twitch emote",
      "illustration",
      "YCH",
      "adopt"
    ]

    {:ok,
     assign(socket,
       offerings: offerings,
       studios: studios,
       featured_studios: featured_studios,
       categories: categories
     )}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("search", search, socket) do
    params = []

    params =
      if search["query"] && search["query"] != "" do
        [{:q, search["query"]} | params]
      else
        params
      end

    {:noreply,
     socket
     |> push_redirect(to: Routes.discover_index_path(Endpoint, :index, "offerings", params))}
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
              <Carousel.Slide class="carousel-item w-full aspect-header-image">
                <LiveRedirect
                  class="w-full h-full aspect-header-image relative"
                  to={Routes.studio_shop_path(Endpoint, :show, studio.handle)}
                >
                  <img
                    class="object-cover aspect-header-image w-full"
                    src={Routes.public_image_path(Endpoint, :image, :studio_header_img, studio.header_img_id)}
                  />
                  <div class="absolute top-2 left-2 md:top-6 md:left-6 text-3xl sm:text-3xl md:text-6xl font-bold text-white text-shadow-lg shadow-black">
                    {studio.name}
                  </div>
                </LiveRedirect>
              </Carousel.Slide>
            {/for}
          </Carousel>
        </div>
      </:hero>
      <div class="flex flex-col gap-2">
        <Form for={:search} submit="search" class="w-full">
          <div class="flex flex-row flex-nowrap w-full md:w-content max-w-xl mx-auto">
            <Field name={:query} class="w-full">
              <TextInput
                name={:query}
                class="w-full input input-bordered"
                opts={placeholder: "Search for offerings..."}
              />
            </Field>
            <Submit class="btn btn-round">
              <i class="fas fa-search" />
            </Submit>
          </div>
        </Form>
        <div class="flex flex-row flex-wrap gap-2 mx-auto justify-center">
          {#for cat <- @categories}
            <Tag tag={cat} />
          {/for}
        </div>
        <div class="homepage-offerings">
          <div class="pt-6 px-2 flex flex-row items-end">
            <div class="text-xl grow">
              Selected Offerings
            </div>
            <div class="text-md">
              <LiveRedirect
                class="hover:link text-primary"
                to={Routes.discover_index_path(Endpoint, :index, "offerings")}
              >Discover More</LiveRedirect>
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
              <LiveRedirect
                class="hover:link text-primary"
                to={Routes.discover_index_path(Endpoint, :index, "studios")}
              >Discover More</LiveRedirect>
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
