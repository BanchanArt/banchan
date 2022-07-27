defmodule BanchanWeb.CommissionLive.Components.OfferingBox do
  @moduledoc """
  Shows a little box with a basic offering information/header image on the
  commissions page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop offering, :struct, required: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <LiveRedirect
      class={@class}
      to={Routes.offering_show_path(Endpoint, :show, @offering.studio.handle, @offering.type)}
    >
      <img
        :if={!is_nil(@offering.card_img_id)}
        src={Routes.public_image_path(Endpoint, :image, :offering_card_img, @offering.card_img_id)}
        class="aspect-header-image object-cover rounded-box"
      />
      <div class="px-2 text-lg">
        <span class="font-medium">{@offering.name}</span> by {@offering.studio.name}
      </div>
    </LiveRedirect>
    """
  end
end
