defmodule BanchanWeb.Components.MasonryGallery.LiveImgPreview do
  @moduledoc """
  Component for MasonGallery images that are being displayed through
  LiveView's `live_img_preview`.
  """
  use BanchanWeb, :component

  prop entry, :struct, required: true
  prop draggable, :boolean

  def render(assigns) do
    ~F"""
    <div
      id={"entry-" <> @entry.ref}
      data-type="live"
      data-id={@entry.ref}
      :hook="LiveImgPreview"
      class="masonry-item live-preview"
      draggable={if @draggable do
        "true"
      else
        "false"
      end}
    >
      {Phoenix.LiveView.Helpers.live_img_preview(@entry,
        class: "w-full h-full object-cover"
      )}
    </div>
    """
  end
end
