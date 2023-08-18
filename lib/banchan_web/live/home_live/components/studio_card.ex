defmodule BanchanWeb.Components.StudioCard do
  @moduledoc """
  Card for displaying studio information
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Card, Tag}

  prop studio, :struct, required: true

  def render(assigns) do
    tags = Enum.take(assigns.studio.tags, 3)
    extra_tags = Enum.count(assigns.studio.tags) - 3

    ~F"""
    <studio-card>
      <LiveRedirect to={~p"/studios/#{@studio.handle}"}>
        <Card class={"h-full", "border", "rounded-lg", "border-base-content", "border-opacity-10", "bg-base-100", "opacity-50": @studio.archived_at}>
          <:image>
            <div class="relative w-full h-full">
              {#if @studio.card_img_id}
                <img
                  class="object-cover rounded-t-lg aspect-video"
                  alt={"studio card image for #{@studio.name}"}
                  src={~p"/images/studio_card_img/#{@studio.card_img_id}"}
                />
              {#else}
                <div class="rounded-lg aspect-video bg-base-300" />
              {/if}
            </div>
          </:image>
          <:header>
            <div class="text-lg font-bold">{@studio.name}</div>
          </:header>
          <:header_aside>
            {#if !@studio.stripe_charges_enabled}
              <div class="badge badge-warning">Pending</div>
            {/if}
            {#if @studio.archived_at}
              <div class="badge badge-warning">Archived</div>
            {/if}
          </:header_aside>
          <ul class="flex flex-row flex-wrap items-center gap-1 px-4 my-2">
            {#for tag <- tags}
              <li>
                <Tag link={false} tag={tag} />
              </li>
            {/for}
            {#if extra_tags > 0}
              <li class="px-1 text-sm text-base-content-300">+{extra_tags} more</li>
            {/if}
          </ul>
        </Card>
      </LiveRedirect>
    </studio-card>
    """
  end
end
