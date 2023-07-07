defmodule BanchanWeb.Components.MasonryGallery.LiveImgPreview do
  @moduledoc """
  Component for MasonGallery images that are being displayed through
  LiveView's `live_img_preview`.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Lightbox

  prop entry, :struct, required: true
  prop editable, :boolean
  prop deleted, :event

  def render(assigns) do
    ~F"""
    <div
      id={"-entry-" <> @entry.uuid}
      data-type="live"
      data-id={@entry.ref}
      class="my-0 sm:mb-2 masonry-item live-preview relative sm:hover:scale-105 sm:hover:z-10 transition-all cursor-pointer"
      draggable={if @editable do
        "true"
      else
        "false"
      end}
    >
      {#if @editable}
        <button
          type="button"
          phx-value-type="live"
          phx-value-id={@entry.ref}
          class="btn btn-xs btn-circle absolute left-2 top-2"
          :on-click={@deleted}
        >✕</button>
      {/if}
      <Lightbox.Item>
        <.live_img_preview entry={@entry} class="w-full h-full object-cover" />
      </Lightbox.Item>
    </div>
    """
  end
end
