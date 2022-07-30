defmodule BanchanWeb.Components.StudioCard do
  @moduledoc """
  Card for displaying studio information
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Card, Tag}
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
                src={Routes.public_image_path(Endpoint, :image, :studio_card_img, @studio.card_img_id)}
              />
            {#else}
              <div class="aspect-video bg-base-300" />
            {/if}
          </:image>
          <:header>
            <div class="text-lg font-bold">{@studio.name}</div>
          </:header>
          <:header_aside>
            {#if !@studio.stripe_charges_enabled}
              <div class="badge badge-warning">Pending</div>
            {/if}
          </:header_aside>
          <ul class="my-2 flex flex-row flex-wrap gap-1">
            {#for tag <- @studio.tags}
              <Tag tag={tag} />
            {/for}
          </ul>
        </Card>
      </LiveRedirect>
    </studio-card>
    """
  end
end
