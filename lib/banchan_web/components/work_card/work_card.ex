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
