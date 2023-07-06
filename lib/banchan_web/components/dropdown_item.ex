defmodule BanchanWeb.Components.DropdownItem do
  @moduledoc """
  Dropdown items for use with BanchanWeb.Components.Dropdown.
  """
  use BanchanWeb, :component

  prop class, :css_class

  slot default

  def render(assigns) do
    ~F"""
    <li class={
      "text-base-content",
      @class
    }>
      <#slot />
    </li>
    """
  end
end
