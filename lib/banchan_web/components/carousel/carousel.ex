defmodule BanchanWeb.Components.Carousel do
  @moduledoc """
  Carousel component using Splidejs
  """
  use BanchanWeb, :live_component

  prop label, :string
  prop class, :css_class

  slot default

  def render(assigns) do
    ~F"""
    <section
      phx-update="ignore"
      id={@id <> "-splide"}
      :hook="SplideHook"
      class={"splide", @class}
      aria-label={@label}
    >
      <div class="splide__track">
        <ul class="splide__list">
          <#slot />
        </ul>
      </div>
    </section>
    """
  end
end
