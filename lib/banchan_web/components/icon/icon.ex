defmodule BanchanWeb.Components.Icon do
  @moduledoc """
  Font icons used across Banchan.

  All icons must be listed in icon.hooks.js in order to be used here.
  """
  use BanchanWeb, :component

  prop name, :string, required: true
  prop class, :css_class
  prop gap, :number, default: 1

  slot default

  def render(assigns) do
    ~F"""
    <div class={"inline flex flex-row gap-#{@gap}", @class}>
      <i
        id={for _ <- 1..10,
            into: "",
            do: <<Enum.random('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')>>}
        :hook="Icon"
        data-lucide={@name}
      /><#slot />
    </div>
    """
  end
end
