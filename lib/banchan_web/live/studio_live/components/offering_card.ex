defmodule BanchanWeb.StudioLive.Components.OfferingCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveRedirect

  alias Banchan.Offerings
  alias Banchan.Uploads.Upload

  alias BanchanWeb.Components.{Button, Card, MasonryGallery, Modal}
  alias BanchanWeb.Endpoint

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop studio, :struct, required: true
  prop offering, :struct, required: true
  prop unarchive, :event, required: true

  data gallery_images, :list, default: []
  data base_price, :list
  data available_slots, :integer

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    base_price = Offerings.offering_base_price(socket.assigns.offering)

    available_slots = Offerings.offering_available_slots(socket.assigns.offering)

    gallery_images =
      socket.assigns.offering.gallery_img_ids
      |> Enum.map(&{:existing, %Upload{id: &1}})

    {:ok,
     socket
     |> assign(base_price: base_price)
     |> assign(available_slots: available_slots)
     |> assign(gallery_images: gallery_images)}
  end

  @impl true
  def handle_event("notify_me", _, socket) do
    if socket.assigns.current_user do
      Offerings.Notifications.subscribe_user!(
        socket.assigns.current_user,
        socket.assigns.offering
      )

      send_update(__MODULE__, id: socket.assigns.id)
      {:noreply, socket}
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

    send_update(__MODULE__, id: socket.assigns.id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_gallery", _, socket) do
    Modal.show(socket.assigns.id <> "_gallery")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="h-full relative">
      {#if @offering.archived_at}
        <Button
          class="btn-primary z-50 absolute top-4 right-4"
          click={@unarchive}
          opts={
            phx_value_type: @offering.type
          }
        >Unarchive</Button>
      {/if}
      <Card class={"h-full", "opacity-50": !is_nil(@offering.archived_at)}>
        <:header>
          <div class="text-lg font-bold">{@offering.name}</div>
        </:header>
        <:header_aside>
          {#if @offering.open && !is_nil(@offering.slots)}
            <div class="whitespace-nowrap badge badge-outline badge-success cursor-default">{@available_slots}/{@offering.slots} Slots</div>
          {#elseif !@offering.open && !is_nil(@offering.slots)}
            <div class="badge badge-error badge-outline cursor-default">0/{@offering.slots} Slots</div>
          {#elseif @offering.open}
            <div class="badge badge-success badge-outline cursor-default">Open</div>
          {#else}
            <div class="badge badge-error badge-outline cursor-default">Closed</div>
          {/if}
          {#if @offering.hidden}
            <div class="badge badge-error badge-outline cursor-default">Hidden</div>
          {/if}
        </:header_aside>
        <:image>
          <img
            draggable="false"
            :on-click="open_gallery"
            class="object-cover hover:cursor-pointer hover:opacity-50 transition-all"
            src={if @offering.card_img_id do
              Routes.public_image_path(Endpoint, :image, @offering.card_img_id)
            else
              Routes.static_path(Endpoint, "/images/640x360.png")
            end}
          />
        </:image>
        <div class="flex flex-col grow">
          <p class="mt-2 grow flex text-ellipsis overflow-hidden h-full">{@offering.description}</p>
          <p class="text-success mt-2 grow-0">
            <span class="font-bold">Base Price:</span>
            {#if @base_price && !Enum.empty?(@base_price)}
              <span class="float-right">{@base_price |> Enum.map(fn {_, amt} -> Money.to_string(amt) end) |> Enum.join(" + ")}</span>
            {#else}
              <span class="float-right">Inquire</span>
            {/if}
          </p>
        </div>
        <:footer>
          <div :if={is_nil(@offering.archived_at)} class="flex flex-row justify-end card-actions">
            {#if @current_user_member?}
              <LiveRedirect
                to={Routes.studio_offerings_edit_path(Endpoint, :edit, @studio.handle, @offering.type)}
                class="btn text-center btn-primary"
              >Edit</LiveRedirect>
            {/if}
            {#if @offering.open}
              <LiveRedirect
                to={Routes.studio_commissions_new_path(Endpoint, :new, @studio.handle, @offering.type)}
                class="btn text-center btn-info"
              >Request</LiveRedirect>
            {#elseif !@offering.user_subscribed?}
              <Button class="btn-info" click="notify_me">Notify Me</Button>
            {/if}
            {#if @offering.user_subscribed?}
              <Button class="btn-info" click="unnotify_me">Unsubscribe</Button>
            {/if}
          </div>
        </:footer>
      </Card>

      {!-- Gallery modal --}
      <div class="cursor-default">
        <Modal id={@id <> "_gallery"}>
          <:title>{@offering.name}</:title>
          {#if Enum.empty?(@gallery_images)}
            <img
              class="object-cover w-full h-full"
              src={if @offering.card_img_id do
                Routes.public_image_path(Endpoint, :image, @offering.card_img_id)
              else
                Routes.static_path(Endpoint, "/images/640x360.png")
              end}
            />
          {#else}
            <MasonryGallery id={@id <> "-masonry-gallery"} images={@gallery_images} />
          {/if}
        </Modal>
      </div>
    </div>
    """
  end
end
