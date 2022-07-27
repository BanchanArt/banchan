defmodule BanchanWeb.Components.MasonryGallery.Upload do
  @moduledoc """
  Component for MasonGallery images that have already been uploaded.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Lightbox

  prop upload, :struct, required: true
  prop type, :atom, required: true
  prop download_original, :boolean, default: false
  prop editable, :boolean
  prop deleted, :event

  def render(assigns) do
    ~F"""
    <div
      class="my-0 sm:mb-2 masonry-item upload-preview relative sm:hover:scale-105 sm:hover:z-10 cursor-pointer transition-all"
      data-type="existing"
      data-id={@upload.id}
      draggable={if @editable do
        "true"
      else
        "false"
      end}
    >
      {#if @editable}
        <button
          type="button"
          phx-value-type="existing"
          phx-value-id={@upload.id}
          class="btn btn-xs btn-circle absolute right-2 top-2"
          :on-click={@deleted}
        >✕</button>
      {/if}
      {#if @upload.pending}
        <div class="w-full h-full bg-base-content animate-pulse" />
      {#else}
        <Lightbox.Item>
          <img
            class="w-full h-full object-cover"
            src={Routes.public_image_path(Endpoint, :image, @type, @upload.id)}
          />
        </Lightbox.Item>
      {/if}
    </div>
    """
  end
end
