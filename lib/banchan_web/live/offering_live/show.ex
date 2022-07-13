defmodule BanchanWeb.OfferingLive.Show do
  @moduledoc """
  Shows details about an offering.
  """
  use BanchanWeb, :surface_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Commissions.LineItem
  alias Banchan.Offerings

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.CommissionLive.Components.Summary
  alias BanchanWeb.Components.{Button, Layout, Lightbox, Markdown, MasonryGallery}
  alias BanchanWeb.StudioLive.Components.OfferingCard

  @impl true
  def handle_params(%{"offering_type" => offering_type} = params, uri, socket) do
    socket = assign_studio_defaults(params, socket, false, true)

    offering =
      Offerings.get_offering_by_type!(
        socket.assigns.studio,
        offering_type,
        socket.assigns.current_user_member?
      )

    gallery_images =
      offering.gallery_uploads
      |> Enum.map(&{:existing, &1})

    line_items =
      offering.options
      |> Enum.filter(& &1.default)
      |> Enum.map(fn option ->
        %LineItem{
          option: option,
          amount: option.price,
          name: option.name,
          description: option.description,
          sticky: option.sticky
        }
      end)

    available_slots = Offerings.offering_available_slots(offering)

    related =
      Offerings.list_offerings(
        related_to: offering,
        order_by: :featured,
        page_size: 6
      )

    cond do
      (offering.mature || offering.studio.mature) && !socket.assigns.current_user.mature_ok ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "This offering is marked as mature, but you have not enabled mature content. You can enable this in your user settings."
         )
         |> push_redirect(to: Routes.discover_index_path(Endpoint, :index, "offerings"))}

      is_nil(offering.archived_at) || socket.assigns.current_user_member? ->
        {:noreply,
         socket
         |> assign(
           uri: uri,
           offering: offering,
           gallery_images: gallery_images,
           line_items: line_items,
           available_slots: available_slots,
           related: related
         )}

      true ->
        {:noreply,
         socket
         |> put_flash(:error, "This offering is unavailable.")
         |> push_redirect(to: Routes.discover_index_path(Endpoint, :index, "offerings"))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <h1 class="text-3xl">
        {@offering.name}
      </h1>
      <div class="divider" />
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="flex flex-col md:order-2 gap-2">
          <Lightbox
            id="card-lightbox-mobile"
            class="md:hidden w-full h-full bg-base-300 rounded-lg aspect-video mb-4"
          >
            <Lightbox.Item>
              <img
                class="w-full h-full object-contain aspect-video"
                src={if @offering.card_img_id do
                  Routes.public_image_path(Endpoint, :image, @offering.card_img_id)
                else
                  Routes.static_path(Endpoint, "/images/640x360.png")
                end}
              />
            </Lightbox.Item>
          </Lightbox>
          <div class="flex flex-row flex-wrap items-center gap-2">
            <div class="md:text-xl grow">
              By
              <LiveRedirect
                class="hover:link font-bold"
                to={Routes.studio_shop_path(Endpoint, :show, @offering.studio.handle)}
              >{@offering.studio.name}</LiveRedirect>
            </div>
            {#if @offering.mature}
              <div class="badge badge-error badge-outline">18+</div>
            {/if}
            {#if @offering.hidden}
              <div class="badge badge-error badge-outline">Hidden</div>
            {#elseif @offering.open && !is_nil(@offering.slots)}
              <div class="whitespace-nowrap badge badge-outline badge-primary">{@available_slots}/{@offering.slots} Slots</div>
            {#elseif !@offering.open && !is_nil(@offering.slots)}
              <div class="badge badge-error badge-outline">0/{@offering.slots} Slots</div>
            {#elseif @offering.open}
              <div class="badge badge-primary badge-outline">Open</div>
            {#else}
              <div class="badge badge-error badge-outline">Closed</div>
            {/if}
          </div>
          <div class="divider" />
          <Summary line_items={@line_items} offering={@offering} studio={@studio} />
          {#if !Enum.empty?(@offering.tags)}
            <h3 class="pt-2 text-lg">Tags</h3>
            <ul class="flex flex-row flex-wrap gap-1">
              {#for tag <- @offering.tags}
                <li class="badge badge-sm badge-primary p-2 cursor-default overflow-hidden">{tag}</li>
              {/for}
            </ul>
            <div class="divider" />
          {/if}
          <div class="flex flex-row justify-end gap-2">
            {#if @current_user_member?}
              <LiveRedirect
                to={Routes.studio_offerings_edit_path(Endpoint, :edit, @offering.studio.handle, @offering.type)}
                class="btn text-center btn-link"
              >Edit</LiveRedirect>
            {/if}
            {#if @offering.open}
              <LiveRedirect
                to={Routes.offering_request_path(Endpoint, :new, @offering.studio.handle, @offering.type)}
                class="btn text-center btn-primary grow"
              >Request</LiveRedirect>
            {#elseif !@offering.user_subscribed?}
              <Button class="btn-info" click="notify_me">Notify Me</Button>
            {/if}
            {#if @offering.user_subscribed?}
              <Button class="btn-info" click="unnotify_me">Unsubscribe</Button>
            {/if}
          </div>
          {#if !Enum.empty?(@related)}
            <div class="hidden md:flex md:flex-col">
              <div class="pt-4 text-2xl">Discover More</div>
              <div class="p-2 flex flex-col">
                {#for {rel, idx} <- Enum.with_index(@related)}
                  <OfferingCard id={"related-desktop-#{idx}"} current_user={@current_user} offering={rel} />
                {/for}
              </div>
            </div>
          {/if}
        </div>
        <div class="divider md:hidden" />
        <div class="flex flex-col md:col-span-2 md:order-1 gap-4">
          <Lightbox
            id="card-lightbox-md"
            class="hidden md:block w-full h-full bg-base-300 rounded-lg aspect-video"
          >
            <Lightbox.Item>
              <img
                class="w-full h-full object-contain aspect-video"
                src={if @offering.card_img_id do
                  Routes.public_image_path(Endpoint, :image, @offering.card_img_id)
                else
                  Routes.static_path(Endpoint, "/images/640x360.png")
                end}
              />
            </Lightbox.Item>
          </Lightbox>
          <div class="rounded-lg shadow-lg bg-base-200 p-4">
            <div class="text-2xl">Description</div>
            <div class="divider" />
            <Markdown class="pb-4" content={@offering.description} />
          </div>
          {#if !Enum.empty?(@gallery_images)}
            <div class="rounded-lg shadow-lg bg-base-200 p-4">
              <div class="text-2xl">Gallery</div>
              <div class="divider" />
              <MasonryGallery id="masonry-gallery" images={@gallery_images} />
            </div>
          {/if}
          {#if !Enum.empty?(@related)}
            <div class="flex flex-col md:hidden">
              <div class="pt-4 text-2xl">Discover More</div>
              <div class="p-2 flex flex-col">
                {#for {rel, idx} <- Enum.with_index(@related)}
                  <OfferingCard id={"related-mobile-#{idx}"} current_user={@current_user} offering={rel} />
                {/for}
              </div>
            </div>
          {/if}
        </div>
      </div>
    </Layout>
    """
  end
end
