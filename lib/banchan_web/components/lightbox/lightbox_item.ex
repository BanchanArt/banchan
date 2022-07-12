defmodule BanchanWeb.Components.Lightbox.Item do
  @moduledoc """
  Individual items that will be displayed by a lightbox.
  """
  use BanchanWeb, :component

  prop class, :css_class
  prop src, :string, required: true

  # Type of media. Can be :image or :video
  # TODO: Finish adding video support.
  prop media, :string, default: :image

  slot default

  def render(assigns) do
    ~F"""
    <div class={"banchan-lightbox-item cursor-pointer", @class} data-src={@src} data-media={@media}>
      <#slot />
    </div>
    """
  end
end
