defmodule BanchanWeb.StudioLive.Components.OfferingCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveRedirect

  alias Banchan.Offerings

  alias BanchanWeb.Components.OfferingCard
  alias BanchanWeb.Endpoint

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, default: false
  prop offering, :struct, required: true

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

  def render(assigns) do
    ~F"""
    <offering-card class="w-full relative cursor-pointer">
      <LiveRedirect to={Routes.offering_show_path(Endpoint, :show, @offering.studio.handle, @offering.type)}>
        <OfferingCard
          name={@offering.name}
          image={@offering.card_img_id}
          base_price={@base_price}
          archived?={!is_nil(@offering.archived_at)}
          mature?={@offering.mature}
          open?={@offering.open}
          hidden?={@offering.hidden}
          total_slots={@offering.slots}
          available_slots={@available_slots}
        />
      </LiveRedirect>
    </offering-card>
    """
  end
end
