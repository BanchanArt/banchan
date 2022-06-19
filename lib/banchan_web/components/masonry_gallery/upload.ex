defmodule BanchanWeb.Components.MasonryGallery.Upload do
  @moduledoc """
  Component for MasonGallery images that have already been uploaded.
  """
  use BanchanWeb, :component

  alias Banchan.Uploads.Upload

  prop upload, :struct, required: true

  defp calculate_span(%Upload{width: width, height: height}) do
    ratio = width / height * 100

    cond do
      ratio >= 180 ->
        # Very Wide
        "row-span-1"

      ratio < 180 && ratio >= 120 ->
        # Wide
        "row-span-2"

      ratio < 120 && ratio >= 80 ->
        # Square-ish
        "row-span-3"

      ratio < 80 && ratio >= 30 ->
        # Tall
        "row-span-4"

      ratio < 30 ->
        # Very tall
        "row-span-5"
    end
  end

  def render(assigns) do
    ~F"""
    <div class={"upload-preview", calculate_span(@upload)}>
      <img
        class="w-full h-full object-cover"
        src={Routes.public_image_path(Endpoint, :image, @upload.id)}
      />
    </div>
    """
  end
end
