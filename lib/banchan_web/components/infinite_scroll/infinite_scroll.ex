defmodule BanchanWeb.Components.InfiniteScroll do
  @moduledoc """
  Infinite scroll triggering component.
  """
  use BanchanWeb, :component

  prop id, :string, required: true
  prop load_more, :event, required: true
  prop page, :integer, required: true

  def render(assigns) do
    ~F"""
    <infinite-scroll
      id={@id}
      class="relative"
      :hook="InfiniteScroll"
      data-page={@page}
      data-event-name={@load_more.name}
      data-event-target={@load_more.target}
    >
      <infinite-scroll-marker class="absolute h-1 w-1 bottom-0" />
    </infinite-scroll>
    """
  end
end
