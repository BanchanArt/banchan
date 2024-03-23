defmodule BanchanWeb.Components.WorkCard do
  @moduledoc """
  Card for displaying work information
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Card, Tag}

  prop work, :struct, required: true

  def render(assigns) do
    tags = Enum.take(assigns.work.tags, 3)
    extra_tags = Enum.count(assigns.work.tags) - 3
    preview = Enum.find(assigns.work.uploads, &(!is_nil(&1.preview_id)))

    ~F"""
    <style>
      :deep(bc-card) {
      @apply h-full border rounded-lg border-base-content border-opacity-10 hover:outline hover:outline-primary-focus hover:outline-offset-0 hover:border-primary-focus transition-all;
      }
      :deep(.image-wrapper) {
      @apply relative w-full h-full;
      }
      :deep(img) {
      @apply rounded-t-lg aspect-video w-full h-full;
      object-fit: contain;
      }
      :deep(h3) {
      @apply text-lg font-bold;
      }
      :deep(.tags) {
      @apply flex flex-row flex-wrap items-center gap-1 px-4 my-2;
      }
      :deep(.extra-tags) {
      @apply px-1 text-sm text-base-content;
      }
    </style>
    <studio-card>
      <LiveRedirect to={~p"/studios/#{@work.studio.handle}/works/#{@work.public_id}"}>
        <Card>
          <:image>
            <div class="image-wrapper">
              {#if !is_nil(preview)}
                <img
                  alt={"work card image for #{@work.title}"}
                  draggable="false"
                  src={~p"/studios/#{@work.studio.handle}/works/#{@work.public_id}/upload/#{preview.upload_id}/preview"}
                />
              {#else}
                <img alt={"work card image for #{@work.title}"} draggable="false" src={~p"/images/640x360.png"}>
              {/if}
            </div>
          </:image>
          <:header>
            <h3>{@work.title}</h3>
          </:header>
          <ul class="tags">
            {#for tag <- tags}
              <li>
                <Tag link={false} tag={tag} />
              </li>
            {/for}
            {#if extra_tags > 0}
              <li class="extra-tags">+{extra_tags} more</li>
            {/if}
          </ul>
        </Card>
      </LiveRedirect>
    </studio-card>
    """
  end
end
