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
  prop current_user_member?, :boolean, default: false
  prop offering, :struct, required: true
  prop unarchive, :event

  data base_price, :list
  data available_slots, :integer

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    base_price = Offerings.offering_base_price(socket.assigns.offering)

    available_slots = Offerings.offering_available_slots(socket.assigns.offering)

    {:ok,
     socket
     |> assign(base_price: base_price)
     |> assign(available_slots: available_slots)}
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
    <offering-card class="w-full relative cursor-pointer">
      <LiveRedirect to={Routes.offering_show_path(Endpoint, :show, @offering.studio.handle, @offering.type)}>
        {#if @offering.archived_at && @unarchive}
          <Button
            class="btn-primary z-50 absolute top-4 right-4"
            click={@unarchive}
            opts={
              phx_value_type: @offering.type
            }
          >Unarchive</Button>
        {/if}

        <Card class={
          "h-full sm:hover:scale-105 sm:hover:z-10 transition-all",
          "opacity-50": !is_nil(@offering.archived_at)
        }>
          <:header>
            <div class="text-sm sm:text-lg font-bold">{@offering.name}</div>
          </:header>
          <:header_aside>
            <div class="hidden sm:flex flex-row flex-wrap">
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
            {#if @base_price && !Enum.empty?(@base_price)}
              <span class="sm:hidden font-semibold text-sm">{@base_price |> Enum.map(fn {_, amt} -> Money.to_string(amt) end) |> Enum.join(" + ")}</span>
            {#else}
              <span class="sm:hidden font-semibold text-sm">Inquire</span>
            {/if}
          </:header_aside>
          <:image>
            <img
              class={"object-contain aspect-video", "blur-lg": @offering.mature && !@current_user.uncensored_mature}
              draggable="false"
              src={if @offering.card_img_id do
                Routes.public_image_path(Endpoint, :image, @offering.card_img_id)
              else
                Routes.static_path(Endpoint, "/images/640x360.png")
              end}
            />
          </:image>
          <div class="hidden sm:flex flex-col grow z-20">
            <p class="flex flex-row items-end">
              <span class="font-bold grow">Base Price:</span>
              {#if @base_price && !Enum.empty?(@base_price)}
                <span class="font-semibold">{@base_price |> Enum.map(fn {_, amt} -> Money.to_string(amt) end) |> Enum.join(" + ")}</span>
              {#else}
                <span class="font-semibold">Inquire</span>
              {/if}
            </p>
          </div>
        </Card>
      </LiveRedirect>
    </offering-card>
    """
  end
end
