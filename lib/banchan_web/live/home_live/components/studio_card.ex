defmodule BanchanWeb.Components.StudioCard do
  @moduledoc """
  Card for displaying studio information
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  prop studio, :struct, required: true

  def render(assigns) do
    ~F"""
    <studio-card>
      <LiveRedirect to={Routes.studio_shop_path(Endpoint, :show, @studio.handle)}>
        <Card class="h-full sm:hover:scale-105 sm:hover:z-10 transition-all">
          <:image>
            {#if @studio.card_img_id || @studio.header_img_id}
              <img
                class="object-cover aspect-video"
                src={Routes.public_image_path(Endpoint, :image, @studio.card_img_id || @studio.header_img_id)}
              />
            {#else}
              <div class="aspect-video bg-base-300" />
            {/if}
          </:image>
          <:header>
            <div class="text-lg font-bold">{@studio.name}</div>
          </:header>
          <div class="content">
            {@studio.about && raw(HtmlSanitizeEx.strip_tags(Earmark.as_html!(@studio.about)))}
          </div>
        </Card>
      </LiveRedirect>
    </studio-card>
    """
  end
end
