defmodule BanchanWeb.Components.MasonryGallery.LiveImgPreview do
  @moduledoc """
  Component for MasonGallery images that are being displayed through
  LiveView's `live_img_preview`.
  """
  use BanchanWeb, :component

  prop entry, :struct, required: true

  def render(assigns) do
    ~F"""
    <div id={"entry-" <> @entry.ref} :hook="LiveImgPreview" class="live-preview">
      {Phoenix.LiveView.Helpers.live_img_preview(@entry,
        class: "w-full h-full object-cover"
      )}
    </div>
    """
  end
end
