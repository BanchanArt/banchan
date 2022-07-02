defmodule BanchanWeb.CommissionLive.Components.StudioBox do
  @moduledoc """
  Shows a little box with basic studio information/header image on the
  commissions page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop studio, :struct, required: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <LiveRedirect class={@class} to={Routes.studio_shop_path(Endpoint, :show, @studio.handle)}>
      <img
        :if={!is_nil(@studio.header_img_id)}
        src={Routes.public_image_path(Endpoint, :image, @studio.header_img_id)}
        class="aspect-header-image object-cover rounded-box"
      />
      <img
        :if={is_nil(@studio.header_img_id) && !is_nil(@studio.card_img_id)}
        src={Routes.public_image_path(Endpoint, :image, @studio.card_img_id)}
        class="aspect-header-image object-cover rounded-box"
      />
      <div class="px-2 text-xl font-medium">
        By {@studio.name}
      </div>
    </LiveRedirect>
    """
  end
end
