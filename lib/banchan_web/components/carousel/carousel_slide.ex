defmodule BanchanWeb.Components.Carousel.Slide do
  @moduledoc """
  Slide for the Carousel component
  """
  use BanchanWeb, :component

  prop class, :css_class

  slot default

  def render(assigns) do
    ~F"""
    <li class={"splide__slide", @class}><#slot /></li>
    """
  end
end
