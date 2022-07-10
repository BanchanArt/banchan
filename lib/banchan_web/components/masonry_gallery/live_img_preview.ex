defmodule BanchanWeb.Components.MasonryGallery.LiveImgPreview do
  @moduledoc """
  Component for MasonGallery images that are being displayed through
  LiveView's `live_img_preview`.
  """
  use BanchanWeb, :component

  prop entry, :struct, required: true
  prop editable, :boolean
  prop deleted, :event

  def render(assigns) do
    ~F"""
    <div
      id={"-entry-" <> @entry.uuid}
      data-type="live"
      data-id={@entry.ref}
      class={"my-0 sm:mb-2 masonry-item live-preview relative", "hover:cursor-move": @editable}
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
          class="btn btn-xs btn-circle absolute right-2 top-2"
          :on-click={@deleted}
        >✕</button>
      {/if}
      {Phoenix.LiveView.Helpers.live_img_preview(@entry,
        class: "w-full h-full object-cover"
      )}
    </div>
    """
  end
end
