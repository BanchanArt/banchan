defmodule BanchanWeb.Components.Icon do
  @moduledoc """
  Font icons used across Banchan.

  All icons must be listed in icon.hooks.js in order to be used here.
  """
  use BanchanWeb, :component

  prop name, :string, required: true
  prop class, :css_class
  prop gap, :number, default: 2
  prop size, :number, default: 6
  prop label, :string, required: false

  slot default

  def render(assigns) do
    ~F"""
    <bc-icon class={"gap-#{@gap}", @class}>
      <i
        id={for _ <- 1..10,
            into: "",
            do: <<Enum.random(~c"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")>>}
        :hook="Icon"
        class={"w-#{@size} h-#{@size}"}
        data-lucide={@name}
        aria-label={@label}
      /><#slot />
    </bc-icon>
    """
  end
end
