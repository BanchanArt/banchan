defmodule BanchanWeb.StudioLive.Components.CommissionCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveRedirect

  alias Banchan.Offerings

  alias BanchanWeb.Components.{Button, Card}
  alias BanchanWeb.Endpoint

  prop current_user, :struct, required: true
  prop studio, :struct, required: true
  prop offering, :struct, required: true

  data base_price, :integer
  data available_slots, :integer
  data subscribed?, :boolean

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    base_price = Offerings.offering_base_price(socket.assigns.offering)
    available_slots = Offerings.offering_available_slots(socket.assigns.offering)

    subscribed? =
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
    Offerings.Notifications.subscribe_user!(socket.assigns.current_user, socket.assigns.offering)
    send_update(__MODULE__, id: socket.assigns.id)
    {:noreply, socket}
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
    <Card>
      <:header>
        <div class="text-lg font-bold">{@offering.name}</div>
      </:header>
      <:header_aside>
        {#if @offering.open && !is_nil(@offering.slots)}
          <div class="badge badge-outline badge-success">{@available_slots}/{@offering.slots} Slots</div>
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
        <img class="object-cover" src={Routes.static_path(Endpoint, "/images/hj-illustration.jpg")}>
      </:image>
      <div class="flex flex-col grow">
        <p class="mt-2 grow flex">{@offering.description}</p>
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
        <div class="flex flex-row justify-end card-actions">
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
    """
  end
end
