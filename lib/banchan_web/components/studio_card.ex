defmodule BanchanWeb.Components.StudioCard do
  @moduledoc """
  Card for displaying studio information
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Endpoint

  prop studio, :any

  def render(assigns) do
    ~F"""
    <LiveRedirect to={Routes.studio_show_path(Endpoint, :show, @studio.slug)}>
      <div class="card">
        <div class="card-image">
          <figure class="image is-2by1">
            <img src={Routes.static_path(Endpoint, "/images/shop_card_default.png")} />
          </figure>
        </div>
        <div class="card-content">
          <div class="media">
            <div class="media-left">
              <figure class="image is-48x48">
                <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")} />
              </figure>
            </div>
            <div class="media-content">
              <p class="title is-4">{@studio.name}</p>
            </div>
          </div>
          <div class="content">
            {@studio.description}
          </div>
        </div>
      </div>
    </LiveRedirect>
    """
  end
end
