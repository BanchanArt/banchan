defmodule BanchanWeb.Components.MasonryGallery do
  @moduledoc """
  Masonry gallery component. Arranges a bunch of Uploads into a nice gallery grid.
  """
  use BanchanWeb, :component

  alias Banchan.Uploads.Upload

  prop uploads, :list, required: true

  defp calculate_span(%Upload{width: width, height: height}) do
    ratio = (width / height) * 100
    cond do
      ratio >= 140 ->
        # Wide
        "col-span-1"
      (ratio >= 100 && ratio < 140) || (ratio < 100 && ratio > 80) ->
        # Square-ish
        "col-span-2"
      ratio <= 80 && ratio > 50 ->
        # Tall
        "col-span-3"
      ratio <= 50 ->
        # Very tall
        "col-span-4"
    end
  end

  def render(assigns) do
    ~F"""
    <div class="grid auto-rows-min gap-2 grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      {#for upload <- @uploads}
        <div class={calculate_span(upload)}>
          <img class="object-cover" src={Routes.public_image_path(Endpoint, :image, upload.id)}>
        </div>
      {/for}
    </div>
    """
  end
end
