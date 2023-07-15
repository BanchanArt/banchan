defmodule BanchanWeb.Components.Dropdown do
  @moduledoc """
  Non-form dropdown with fancier features than Select. Meant more for things
  like dropdowns that change things and such.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  prop class, :css_class
  prop label, :string, required: true
  prop show_caret?, :boolean

  slot default

  def render(assigns) do
    ~F"""
    <bc-dropdown class="dropdown">
      <label tabindex="0" class={@class}>
        {@label}
        {#if @show_caret?}
          <Icon name="chevron-down" />
        {/if}
      </label>
      <ul tabindex="0" class="dropdown-content menu shadow z-[1] bg-base-200 rounded-box w-52">
        <#slot />
      </ul>
    </bc-dropdown>
    """
  end
end
