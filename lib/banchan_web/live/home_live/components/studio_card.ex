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
    <LiveRedirect to={Routes.studio_shop_path(Endpoint, :show, @studio.handle)}>
      <figure class="image object-scale-down max-w-md">
        {#if @studio.card_img_id || @studio.header_img_id}
          <img
            class="object-cover aspect-video w-full"
            src={Routes.public_image_path(Endpoint, :image, @studio.card_img_id || @studio.header_img_id)}
          />
        {#else}
          <div class="aspect-video bg-base-300 w-full" />
        {/if}
      </figure>
      <div class="m-3">
        <div class="media">
          <div class="float-left">
            <figure class="image">
              <img
                src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
                class="inline-block object-scale-down h-12 p-1"
              />
            </figure>
          </div>
          <div class="media-content">
            <p class="text-xl font-medium md:leading-loose">{@studio.name}</p>
          </div>
        </div>
        <br>
        <div class="content">
          {@studio.about && raw(HtmlSanitizeEx.strip_tags(Earmark.as_html!(@studio.about)))}
        </div>
      </div>
    </LiveRedirect>
    """
  end
end
