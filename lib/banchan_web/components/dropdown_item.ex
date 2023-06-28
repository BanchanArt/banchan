defmodule BanchanWeb.Components.DropdownItem do
  @moduledoc """
  Dropdown items for use with BanchanWeb.Components.Dropdown.
  """
  use BanchanWeb, :component

  prop class, :css_class
  prop label, :string, required: true
  prop click, :event, required: true
  prop value, :any
  prop description, :string

  def render(assigns) do
    ~F"""
    <li class={
      "text-base-content",
      @class
    }>
      <button :on-click={@click} value={@value}>
        <div class="flex flex-col items-start">
          <span>{@label}</span>
          {#if @description}
            <span class="text-xs text-base-content text-left opacity-50">
              {@description}
            </span>
          {/if}
        </div>
      </button>
    </li>
    """
  end
end
