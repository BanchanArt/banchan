defmodule BanchanWeb.StudioLive.Components.OfferingCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveRedirect

  alias Banchan.Offerings

  alias BanchanWeb.Components.OfferingCard

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, default: false
  prop offering, :struct, required: true
  prop display_studio?, :boolean, default: false

  data available_slots, :integer

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    available_slots = Offerings.offering_available_slots(socket.assigns.offering)

    {:ok, socket |> assign(available_slots: available_slots)}
  end

  def render(assigns) do
    ~F"""
    <offering-card class="w-full relative cursor-pointer">
      <LiveRedirect to={~p"/studios/#{@offering.studio.handle}/offerings/#{@offering.type}"}>
        <OfferingCard
          name={@offering.name}
          image={@offering.card_img_id}
          base_price={@offering.base_price}
          has_addons?={@offering.has_addons}
          archived?={!is_nil(@offering.archived_at)}
          mature?={@offering.mature}
          uncensored?={!is_nil(@current_user) && @current_user.uncensored_mature}
          open?={@offering.open}
          hidden?={@offering.hidden}
          total_slots={@offering.slots}
          available_slots={@available_slots}
          studio_name={if @display_studio?, do: @offering.studio.name, else: nil}
        />
      </LiveRedirect>
    </offering-card>
    """
  end
end
