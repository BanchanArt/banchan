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
    <div
      id={@id}
      :hook="InfiniteScroll"
      data-page={@page}
      data-event-name={@load_more.name}
      data-event-target={@load_more.target}
    />
    """
  end
end
