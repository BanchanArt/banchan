defmodule BanchanWeb.Components.WorkGallery do
  @moduledoc """
  Component for displaying a masonry-style gallery of Works.
  """
  use BanchanWeb, :component

  alias Banchan.Works

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Icon

  prop works, :any
  prop show_non_media, :boolean, default: false

  slot default

  def render(assigns) do
    ~F"""
    <work-gallery>
      <ul>
        {#if slot_assigned?(:default)}
          <li>
            <#slot />
          </li>
        {/if}
        {#for work <- @works}
          {#if Works.first_previewable_upload(work) || @show_non_media}
            <li>
              <LiveRedirect to={~p"/studios/#{work.studio.handle}/works/#{work.public_id}"}>
                {#if Works.first_previewable_upload(work)}
                  <img
                    src={~p"/studios/#{work.studio.handle}/works/#{work.public_id}/upload/#{Works.first_previewable_upload(work).upload_id}/preview"}
                    alt={work.title}
                  />
                {#else}
                  <div>
                    <Icon name="file-up" size={32} label={Enum.at(work.uploads, 0).upload.name}>
                      <span>{Enum.at(work.uploads, 0).upload.name}</span>
                    </Icon>
                  </div>
                {/if}
              </LiveRedirect>
            </li>
          {/if}
        {#else}
          Nothing to see here
        {/for}
      </ul>
    </work-gallery>
    """
  end
end
