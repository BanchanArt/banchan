defmodule BanchanWeb.Components.Lightbox do
  @moduledoc """
  Lightbox media previewer meant for individual images.
  """
  use BanchanWeb, :live_component

  prop class, :css_class

  slot default

  def render(assigns) do
    ~F"""
    <lightbox-wrapper id={@id <> "-lightbox-wrapper"} :hook="Lightbox" class={@class}>
      <#slot />
    </lightbox-wrapper>
    """
  end
end
