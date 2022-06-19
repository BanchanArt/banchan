defmodule BanchanWeb.Components.MasonryGallery do
  @moduledoc """
  Masonry gallery component. Arranges a bunch of Uploads into a nice gallery grid.
  """
  use BanchanWeb, :component

  slot default

  def render(assigns) do
    ~F"""
    <div class="grid auto-rows-gallery gap-0.5 grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      <#slot name="default" />
    </div>
    """
  end
end
