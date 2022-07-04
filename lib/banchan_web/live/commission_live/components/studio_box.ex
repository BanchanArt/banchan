defmodule BanchanWeb.CommissionLive.Components.StudioBox do
  @moduledoc """
  Shows a little box with basic studio information/header image on the
  commissions page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop commission, :struct, required: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <LiveRedirect class={@class} to={Routes.studio_shop_path(Endpoint, :show, @commission.studio.handle)}>
      <img
        :if={!is_nil(@commission.offering.card_img_id)}
        src={Routes.public_image_path(Endpoint, :image, @commission.offering.card_img_id)}
        class="aspect-header-image object-cover rounded-box"
      />
      <div class="px-2 text-lg">
        <span class="font-medium">{@commission.offering.name}</span> by {@commission.studio.name}
      </div>
    </LiveRedirect>
    """
  end
end
