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

  alias BanchanWeb.CommissionLive.Components.{AddonList, Summary}

  alias BanchanWeb.Components.{
    Button,
    Collapse,
    Icon,
    Layout,
    Lightbox,
    Markdown,
    MasonryGallery,
    OfferingCardImg,
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

    terms = offering.terms || socket.assigns.studio.default_terms

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
          sticky: option.default
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

      offering.mature && !Application.get_env(:banchan, :mature_content_enabled?) ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "This kind of content is currently disabled."
         )
         |> push_navigate(to: Routes.discover_index_path(Endpoint, :index, "offerings"))}

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
           "This offering is marked as mature, but you have not enabled mature content for yourself, meaning it won't show up when you search for it yourself. You can enable this in your user settings."
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
           related: related,
           terms: terms
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
      ~p"/studios/#{socket.assigns.studio.handle}/offerings/#{socket.assigns.offering.type}"
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
      <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div class="flex flex-col gap-2 md:order-2">
          <Lightbox
            id="card-lightbox-mobile"
            class="relative w-full mb-4 overflow-hidden rounded-lg md:hidden aspect-video"
          >
            {#if @offering.card_img && !@offering.card_img.pending}
              <Lightbox.Item>
                <OfferingCardImg image={@offering.card_img} />
              </Lightbox.Item>
            {#else}
              <div class="w-full h-full aspect-video bg-base-300" />
            {/if}
          </Lightbox>
          <div class="flex flex-col flex-wrap items-end gap-2">
            <div class="md:text-xl grow">
              By
              <LiveRedirect
                class="font-bold hover:link"
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
            {#elseif @offering.open}
              <div class="badge badge-primary">Open</div>
            {#else}
              <div class="badge badge-error">Closed</div>
            {/if}
          </div>
          <div class="divider" />
          <div class="flex flex-col p-4 rounded-lg bg-base-200">
            {#if Enum.any?(@offering.options, & &1.default)}
              <div class="px-2 text-sm font-medium opacity-50">Included</div>
              <Summary line_items={@line_items} />
              <div class="divider" />
            {/if}
            {#if Enum.any?(@offering.options, &(!&1.default))}
              <div class="px-2 text-sm font-medium opacity-50">Add-ons</div>
              <AddonList id="addon-list" offering={@offering} line_items={@line_items} />
              <div class="divider" />
            {/if}
            {#if !Enum.empty?(@offering.tags)}
              <h3 class="pt-2 text-lg">Tags</h3>
              <div class="flex flex-row flex-wrap gap-1">
                {#for tag <- @offering.tags}
                  <Tag tag={tag} />
                {/for}
              </div>
              <div class="divider" />
            {/if}
            <div class="flex flex-row justify-end gap-2 pt-4">
              {#if @current_user}
                <div class="dropdown">
                  <label tabindex="0" class="py-0 my-2 btn btn-circle btn-outline btn-sm grow-0">
                    <Icon name="more-vertical" size="4" />
                  </label>
                  <ul
                    tabindex="0"
                    class="p-1 border dropdown-content menu md:menu-compact bg-base-100 border-base-content border-opacity-10 rounded-xl"
                  >
                    {#if @current_user && (@current_user_member? || Accounts.mod?(@current_user))}
                      <li>
                        <LiveRedirect to={~p"/studios/#{@offering.studio.handle}/offerings/#{@offering.type}/edit"}>
                          <Icon name="pencil" size="4" label="edit" /> Edit
                        </LiveRedirect>
                      </li>
                    {/if}
                    <li>
                      <button type="button" :on-click="report">
                        <Icon name="flag" size="4" label="report" /> Report
                      </button>
                    </li>
                  </ul>
                </div>
              {/if}
              {#if @offering.open}
                <LiveRedirect
                  to={~p"/studios/#{@offering.studio.handle}/offerings/#{@offering.type}/request"}
                  class="text-center btn btn-primary grow"
                >Request</LiveRedirect>
              {#elseif !@offering.user_subscribed?}
                <Button class="btn-info grow" click="notify_me">Notify Me</Button>
              {/if}
              {#if @offering.user_subscribed?}
                <Button class="btn-info grow" click="unnotify_me">Unsubscribe</Button>
              {/if}
            </div>
          </div>
          {#if !Enum.empty?(@related)}
            <div class="hidden md:flex md:flex-col">
              <div class="pt-4 text-2xl">Discover More</div>
              <div class="flex flex-col p-2">
                {#for {rel, idx} <- Enum.with_index(@related)}
                  <OfferingCard id={"related-desktop-#{idx}"} current_user={@current_user} offering={rel} />
                {/for}
              </div>
            </div>
          {/if}
        </div>
        <div class="divider md:hidden" />
        <div class="flex flex-col gap-4 md:col-span-2 md:order-1">
          <Lightbox
            id="card-lightbox-md"
            class="relative hidden w-full overflow-hidden rounded-lg bg-base-300 md:block aspect-video"
          >
            {#if @offering.card_img && !@offering.card_img.pending}
              <Lightbox.Item>
                <OfferingCardImg image={@offering.card_img} />
              </Lightbox.Item>
            {#else}
              <div class="w-full h-full aspect-video bg-base-300" />
            {/if}
          </Lightbox>
          <div class="p-4 rounded-lg bg-base-200">
            <div class="text-2xl">Description</div>
            <div class="divider" />
            <Markdown class="pb-4" content={@offering.description} />
          </div>
          {#if @terms}
            <div class="divider md:hidden" />
            <div class="p-4 rounded-lg bg-base-200">
              <Collapse id="terms-collapse">
                <:header>Commission Terms</:header>
                <Markdown content={@terms} />
              </Collapse>
            </div>
          {/if}
          {#if !Enum.empty?(@gallery_images)}
            <div class="p-4 rounded-lg bg-base-200">
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
              <div class="flex flex-col p-2">
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
