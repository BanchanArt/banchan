defmodule BanchanWeb.OfferingLive.Show do
  @moduledoc """
  Shows details about an offering.
  """
  use BanchanWeb, :live_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Accounts
  alias Banchan.Commissions.LineItem
  alias Banchan.Offerings
  alias Banchan.Offerings.Notifications

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.CommissionLive.Components.Summary

  alias BanchanWeb.Components.{
    Button,
    Collapse,
    Layout,
    Lightbox,
    Markdown,
    MasonryGallery,
    ReportModal,
    Tag
  }

  alias BanchanWeb.StudioLive.Components.OfferingCard

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_params(%{"offering_type" => offering_type} = params, _uri, socket) do
    if socket.assigns[:offering] do
      Notifications.unsubscribe_from_offering_updates(socket.assigns.offering)
    end

    socket = assign_studio_defaults(params, socket, false, true)

    offering =
      Offerings.get_offering_by_type!(
        socket.assigns.current_user,
        socket.assigns.studio,
        offering_type
      )

    Notifications.subscribe_to_offering_updates(offering)

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
        current_user: socket.assigns.current_user,
        order_by: :featured,
        page_size: 6
      )

    cond do
      socket.redirected ->
        {:noreply, socket}

      offering.mature && is_nil(socket.assigns.current_user) ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "You must be signed in to view mature offerings."
         )
         |> push_navigate(to: Routes.discover_index_path(Endpoint, :index, "offerings"))}

      offering.mature && socket.assigns.current_user && !socket.assigns.current_user.mature_ok &&
        !socket.assigns.current_user_member? && !Accounts.mod?(socket.assigns.current_user) ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "This offering is marked as mature, but you have not enabled mature content. You can enable this in your user settings."
         )
         |> push_navigate(to: Routes.discover_index_path(Endpoint, :index, "offerings"))}

      is_nil(offering.archived_at) || socket.assigns.current_user_member? ->
        {:noreply,
         socket
         |> assign(
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
         |> push_navigate(to: Routes.discover_index_path(Endpoint, :index, "offerings"))}
    end
  end

  def handle_info(%{event: "images_updated"}, socket) do
    offering =
      Offerings.get_offering_by_type!(
        socket.assigns.current_user,
        socket.assigns.studio,
        socket.assigns.offering.type
      )

    gallery_images =
      offering.gallery_uploads
      |> Enum.map(&{:existing, &1})

    {:noreply, socket |> assign(offering: offering, gallery_images: gallery_images)}
  end

  @impl true
  def handle_event("notify_me", _, socket) do
    if socket.assigns.current_user do
      Offerings.Notifications.subscribe_user!(
        socket.assigns.current_user,
        socket.assigns.offering
      )

      {:noreply, socket |> assign(offering: %{socket.assigns.offering | user_subscribed?: true})}
    else
      {:noreply,
       socket
       |> put_flash(:info, "You must log in to subscribe.")
       |> redirect(to: Routes.login_path(Endpoint, :new))}
    end
  end

  @impl true
  def handle_event("unnotify_me", _, socket) do
    Offerings.Notifications.unsubscribe_user!(
      socket.assigns.current_user,
      socket.assigns.offering
    )

    {:noreply, socket |> assign(offering: %{socket.assigns.offering | user_subscribed?: false})}
  end

  @impl true
  def handle_event("report", _, socket) do
    ReportModal.show(
      "report-modal",
      Routes.offering_show_url(
        Endpoint,
        :show,
        socket.assigns.studio.handle,
        socket.assigns.offering.type
      )
    )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <h1 class="text-3xl">
        {@offering.name}
      </h1>
      <div class="divider" />
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="flex flex-col md:order-2 gap-2">
          <Lightbox
            id="card-lightbox-mobile"
            class="relative md:hidden w-full rounded-lg aspect-video mb-4 overflow-hidden"
          >
            {#if @offering.card_img && !@offering.card_img.pending}
              <Lightbox.Item>
                <img
                  class="absolute w-full h-full object-contain aspect-video overflow-hidden z-10"
                  src={Routes.public_image_path(Endpoint, :image, :offering_card_img, @offering.card_img_id)}
                />
                <img
                  class="aspect-video w-full h-full blur-lg"
                  draggable="false"
                  src={Routes.public_image_path(Endpoint, :image, :offering_card_img, @offering.card_img_id)}
                />
              </Lightbox.Item>
            {#else}
              <div class="w-full h-full aspect-video bg-base-300" />
            {/if}
          </Lightbox>
          <div class="flex flex-col flex-wrap items-end gap-2">
            <div class="md:text-xl grow">
              By
              <LiveRedirect
                class="hover:link font-bold"
                to={Routes.studio_shop_path(Endpoint, :show, @offering.studio.handle)}
              >{@offering.studio.name}</LiveRedirect>
            </div>
            {#if @offering.mature}
              <div class="badge badge-error">Mature</div>
            {/if}
            {#if @offering.hidden}
              <div class="badge badge-error">Hidden</div>
            {#elseif @offering.open && !is_nil(@offering.slots)}
              <div class="whitespace-nowrap badge badge-primary">{@available_slots}/{@offering.slots} Slots</div>
            {#elseif !@offering.open && !is_nil(@offering.slots)}
              <div class="badge badge-error">0/{@offering.slots} Slots</div>
            {#elseif @offering.open}
              <div class="badge badge-primary">Open</div>
            {#else}
              <div class="badge badge-error">Closed</div>
            {/if}
          </div>
          <div class="divider" />
          <Summary line_items={@line_items} offering={@offering} studio={@studio} />
          {#if !Enum.empty?(@offering.tags)}
            <h3 class="pt-2 text-lg">Tags</h3>
            <div class="flex flex-row flex-wrap gap-1">
              {#for tag <- @offering.tags}
                <Tag tag={tag} />
              {/for}
            </div>
            <div class="divider" />
          {/if}
          <div class="flex flex-row justify-end gap-2">
            {#if @current_user}
              <div class="dropdown">
                <label tabindex="0" class="btn btn-circle btn-outline btn-sm my-2 py-0 grow-0">
                  <i class="fas fa-ellipsis-vertical" />
                </label>
                <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-200 rounded-box">
                  {#if @current_user && (@current_user_member? || Accounts.mod?(@current_user))}
                    <li>
                      <LiveRedirect to={Routes.studio_offerings_edit_path(Endpoint, :edit, @offering.studio.handle, @offering.type)}><i class="fas fa-edit" /> Edit</LiveRedirect>
                    </li>
                  {/if}
                  <li>
                    <button type="button" :on-click="report">
                      <i class="fas fa-flag" /> Report
                    </button>
                  </li>
                </ul>
              </div>
            {/if}
            {#if @offering.open}
              <LiveRedirect
                to={Routes.offering_request_path(Endpoint, :new, @offering.studio.handle, @offering.type)}
                class="btn text-center btn-primary grow"
              >Request</LiveRedirect>
            {#elseif !@offering.user_subscribed?}
              <Button class="btn-info grow" click="notify_me">Notify Me</Button>
            {/if}
            {#if @offering.user_subscribed?}
              <Button class="btn-info grow" click="unnotify_me">Unsubscribe</Button>
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
            class="relative hidden bg-base-300 md:block w-full rounded-lg aspect-video overflow-hidden"
          >
            {#if @offering.card_img && !@offering.card_img.pending}
              <Lightbox.Item>
                <img
                  class="absolute w-full h-full object-contain aspect-video z-10"
                  src={Routes.public_image_path(Endpoint, :image, :offering_card_img, @offering.card_img_id)}
                />
                <img
                  class="aspect-video w-full h-full blur-lg"
                  draggable="false"
                  src={Routes.public_image_path(Endpoint, :image, :offering_card_img, @offering.card_img_id)}
                />
              </Lightbox.Item>
            {#else}
              <div class="w-full h-full aspect-video bg-base-300" />
            {/if}
          </Lightbox>
          <div class="rounded-lg shadow-lg bg-base-200 p-4">
            <div class="text-2xl">Description</div>
            <div class="divider" />
            <Markdown class="pb-4" content={@offering.description} />
          </div>
          {#if @offering.terms}
            <div class="divider md:hidden" />
            <div class="rounded-lg shadow-lg bg-base-200 p-4">
              <Collapse id="terms-collapse">
                <:header>Commission Terms</:header>
                <Markdown content={@offering.terms} />
              </Collapse>
            </div>
          {/if}
          {#if !Enum.empty?(@gallery_images)}
            <div class="rounded-lg shadow-lg bg-base-200 p-4">
              <div class="text-2xl">Gallery</div>
              <div class="divider" />
              <MasonryGallery
                id="masonry-gallery"
                upload_type={:offering_gallery_img}
                images={@gallery_images}
              />
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
      {#if @current_user}
        <ReportModal id="report-modal" current_user={@current_user} />
      {/if}
    </Layout>
    """
  end
end
