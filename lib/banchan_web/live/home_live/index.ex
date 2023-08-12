defmodule BanchanWeb.HomeLive do
  @moduledoc """
  Banchan Homepage
  """
  use BanchanWeb, :live_view

  alias Banchan.Offerings
  alias Banchan.Studios

  alias Surface.Components.{Form, LiveRedirect}
  alias Surface.Components.Form.{Field, Submit}
  alias Surface.Components.Form.TextInput

  alias BanchanWeb.Components.{Carousel, Icon, Layout, StudioCard, Tag}
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
        page_size: 6,
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
     |> push_navigate(to: Routes.discover_index_path(Endpoint, :index, "offerings", params))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    {#if @current_user || is_nil(Application.get_env(:banchan, :basic_auth))}
      <Layout flashes={@flash}>
        <:hero>
          <div id="carousel-handler" class="grow">
            <Carousel id="studio-carousel" label="Featured Studios" class="w-full h-full aspect-header-image">
              {#for studio <- @featured_studios.entries}
                <Carousel.Slide class="w-full carousel-item aspect-header-image">
                  <LiveRedirect
                    class="relative w-full h-full aspect-header-image"
                    to={Routes.studio_shop_path(Endpoint, :show, studio.handle)}
                  >
                    <img
                      class="object-cover w-full aspect-header-image"
                      src={Routes.public_image_path(Endpoint, :image, :studio_header_img, studio.header_img_id)}
                    />
                    <div class="absolute text-3xl font-bold text-white top-2 left-2 md:top-6 md:left-6 sm:text-3xl md:text-6xl text-shadow-black">
                      {studio.name}
                    </div>
                  </LiveRedirect>
                </Carousel.Slide>
              {/for}
            </Carousel>
          </div>
        </:hero>
        <div class="flex flex-col gap-4">
          <Form for={%{}} as={:search} submit="search" class="w-full" opts={role: "search"}>
            <div class="flex flex-row w-full max-w-xl gap-2 mx-auto flex-nowrap md:w-content">
              <Field name={:query} class="w-full">
                <TextInput
                  name={:query}
                  class="w-full input input-bordered"
                  opts={placeholder: "Search for offerings...", "aria-label": "Search for offerings"}
                />
              </Field>
              <Submit class="btn btn-round" opts={"aria-label": "Search"}>
                <Icon name="search" size="4" />
              </Submit>
            </div>
          </Form>
          <div class="flex flex-row flex-wrap items-center justify-center gap-2 mx-auto max-w-7xl">
            {#for cat <- @categories}
              <Tag tag={cat} />
            {/for}
          </div>
          <div class="w-full px-4 mx-auto homepage-offerings max-w-7xl">
            <div class="flex flex-row items-end pt-6">
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
            <div class="flex flex-col gap-4">
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 auto-rows-fr">
                {#for {offering, idx} <- Enum.with_index(@offerings.entries)}
                  <OfferingCard id={"offering-#{idx}"} current_user={@current_user} offering={offering} />
                {/for}
              </div>
            </div>
          </div>
          <div class="w-full px-4 pt-10 mx-auto featured-studios max-w-7xl">
            <div class="flex flex-row items-end">
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
            <div class="flex flex-col gap-4">
              <div class="grid grid-cols-1 gap-4 studio-list sm:grid-cols-2 lg:grid-cols-3 auto-rows-fr">
                {#for studio <- @studios.entries}
                  <StudioCard studio={studio} />
                {/for}
              </div>
            </div>
          </div>
        </div>
      </Layout>
    {#else}
      <Layout flashes={@flash}>
        <div id="above-fold" class="md:px-4">
          <div class="min-h-screen hero">
            <div class="flex flex-col hero-content md:flex-row">
              <div class="flex flex-col items-center max-w-2xl gap-4">
                <div class="text-5xl font-bold">
                  Coming <span class="font-bold text-primary">Soon</span>
                </div>
                <div class="text-lg">
                  <LiveRedirect to={Routes.beta_signup_path(Endpoint, :new)}>Learn More →</LiveRedirect>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Layout>
    {/if}
    """
  end
end
