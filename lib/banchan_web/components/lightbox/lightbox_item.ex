defmodule BanchanWeb.Components.Lightbox.Item do
  @moduledoc """
  Individual items that will be displayed by a lightbox.
  """
  use BanchanWeb, :component

  prop class, :css_class
  prop src, :string
  prop download, :string

  # Type of media. Can be :image or :video
  prop media, :string, default: :image

  slot default

  def render(assigns) do
    ~F"""
    <div
      class={"banchan-lightbox-item cursor-pointer", @class}
      data-src={@src}
      data-media={@media}
      data-download={@download}
    >
      <#slot />
    </div>
    """
  end
end
