defmodule BanchanWeb.StudioLive.Components.OfferingCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveRedirect

  alias Banchan.Offerings

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
      socket.assigns.offering.gallery_uploads
      |> Enum.map(&{:existing, &1})

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
    <offering-card class="w-full relative cursor-pointer" :on-click="open_gallery">
      {#if @offering.archived_at}
        <Button
          class="btn-primary z-50 absolute top-4 right-4"
          click={@unarchive}
          opts={
            phx_value_type: @offering.type
          }
        >Unarchive</Button>
      {/if}

      <Card class={"h-full hover:scale-105 hover:z-10 transition-all", "opacity-50": !is_nil(@offering.archived_at)}>
        <:header>
          <div class="text-lg font-bold">{@offering.name}</div>
        </:header>
        <:header_aside>
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
        </:header_aside>
        <:image>
          <img
            draggable="false"
            src={if @offering.card_img_id do
              Routes.public_image_path(Endpoint, :image, @offering.card_img_id)
            else
              Routes.static_path(Endpoint, "/images/640x360.png")
            end}
          />
        </:image>
        <div class="flex flex-col grow">
          <p class="flex flex-row items-end">
            <span class="font-bold grow">Base Price:</span>
            {#if @base_price && !Enum.empty?(@base_price)}
              <span>{@base_price |> Enum.map(fn {_, amt} -> Money.to_string(amt) end) |> Enum.join(" + ")}</span>
            {#else}
              <span>Inquire</span>
            {/if}
          </p>
        </div>
      </Card>

      {!-- Gallery modal --}
      <div class="cursor-default">
        <Modal id={@id <> "_gallery"} big>
          <div class="px-4">
            <span class="text-xl font-bold">{@offering.name}</span>
            <p class="pb-4 prose">
              {@offering.description}
            </p>
            <ul class="flex flex-row flex-wrap gap-1">
              {#for tag <- @offering.tags}
                <li class="badge badge-sm badge-primary p-2 cursor-default overflow-hidden">{tag}</li>
              {/for}
            </ul>
            <div :if={is_nil(@offering.archived_at)} class="pt-2 flex flex-row justify-end card-actions">
              {#if @current_user_member?}
                <LiveRedirect
                  to={Routes.studio_offerings_edit_path(Endpoint, :edit, @studio.handle, @offering.type)}
                  class="btn text-center btn-primary btn-sm"
                >Edit</LiveRedirect>
              {/if}
              {#if @offering.open}
                <LiveRedirect
                  to={Routes.studio_commissions_new_path(Endpoint, :new, @studio.handle, @offering.type)}
                  class="btn text-center btn-info btn-sm"
                >Request</LiveRedirect>
              {#elseif !@offering.user_subscribed?}
                <Button class="btn-info btn-sm" click="notify_me">Notify Me</Button>
              {/if}
              {#if @offering.user_subscribed?}
                <Button class="btn-info btn-sm" click="unnotify_me">Unsubscribe</Button>
              {/if}
            </div>
          </div>
          <div class="pt-4">
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
          </div>
        </Modal>
      </div>
    </offering-card>
    """
  end
end
