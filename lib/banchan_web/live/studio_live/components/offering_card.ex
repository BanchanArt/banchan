defmodule BanchanWeb.StudioLive.Components.OfferingCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveRedirect

  alias Banchan.Offerings

  alias BanchanWeb.Components.{Button, Card}
  alias BanchanWeb.Endpoint

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop studio, :struct, required: true
  prop offering, :struct, required: true
  prop unarchive, :event, required: true

  data base_price, :integer
  data available_slots, :integer
  data subscribed?, :boolean

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    base_price = Offerings.offering_base_price(socket.assigns.offering)
    available_slots = Offerings.offering_available_slots(socket.assigns.offering)

    subscribed? =
      socket.assigns.current_user &&
        Offerings.Notifications.user_subscribed?(
          socket.assigns.current_user,
          socket.assigns.offering
        )

    {:ok,
     socket
     |> assign(base_price: base_price)
     |> assign(available_slots: available_slots)
     |> assign(subscribed?: subscribed?)}
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
            <div class="whitespace-nowrap badge badge-outline badge-success">{@available_slots}/{@offering.slots} Slots</div>
          {#elseif !@offering.open && !is_nil(@offering.slots)}
            <div class="badge badge-error badge-outline">0/{@offering.slots} Slots</div>
          {#elseif @offering.open}
            <div class="badge badge-success badge-outline">Open</div>
          {#else}
            <div class="badge badge-error badge-outline">Closed</div>
          {/if}
          {#if @offering.hidden}
            <div class="badge badge-error badge-outline">Hidden</div>
          {/if}
        </:header_aside>
        <:image>
          <img
            draggable="false"
            class="object-cover"
            src={if @offering.card_img_id do
              Routes.offering_image_path(Endpoint, :card_image, @offering.card_img_id)
            else
              Routes.static_path(Endpoint, "/images/640x360.png")
            end}
          />
        </:image>
        <div class="flex flex-col grow">
          <p class="mt-2 grow flex text-ellipsis overflow-hidden h-full">{@offering.description}</p>
          <p class="text-success mt-2 grow-0">
            <span class="font-bold">Base Price:</span>
            {#if @base_price}
              <span class="float-right">{@base_price}</span>
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
                class="btn text-center btn-secondary"
              >Edit</LiveRedirect>
            {/if}
            {#if @offering.open}
              <LiveRedirect
                to={Routes.studio_commissions_new_path(Endpoint, :new, @studio.handle, @offering.type)}
                class="btn text-center btn-info"
              >Request</LiveRedirect>
            {#elseif !@subscribed?}
              <Button class="btn-info" click="notify_me">Notify Me</Button>
            {/if}
            {#if @subscribed?}
              <Button class="btn-info" click="unnotify_me">Unsubscribe</Button>
            {/if}
          </div>
        </:footer>
      </Card>
    </div>
    """
  end
end
