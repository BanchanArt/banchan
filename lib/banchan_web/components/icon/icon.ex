defmodule BanchanWeb.Components.Icon do
  @moduledoc """
  Font icons used across Banchan.

  All icons must be listed in icon.hooks.js in order to be used here.
  """
  use BanchanWeb, :component

  prop name, :string, required: true
  prop class, :css_class
  prop gap, :number, default: 1
  prop size, :number, default: 6

  slot default

  def render(assigns) do
    ~F"""
    <style>
      bc-icon {
      @apply flex flex-row;
      }
    </style>
    <bc-icon class={"gap-#{@gap}", @class}>
      <i
        id={for _ <- 1..10,
            into: "",
            do: <<Enum.random(~c"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")>>}
        :hook="Icon"
        class={"w-#{@size} h-#{@size}"}
        data-lucide={@name}
      /><#slot />
    </bc-icon>
    """
  end
end
