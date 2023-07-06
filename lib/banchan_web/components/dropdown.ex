defmodule BanchanWeb.Components.Dropdown do
  @moduledoc """
  Non-form dropdown with fancier features than Select. Meant more for things
  like dropdowns that change things and such.
  """
  use BanchanWeb, :component

  prop class, :css_class
  prop label, :string, required: true
  prop show_caret?, :boolean

  slot default

  def render(assigns) do
    ~F"""
    <details class="dropdown">
      <summary class={@class}>
        {@label}
        <i class="fas fa-chevron-down ml-2" :if={@show_caret?} />
      </summary>
      <ul class="shadow menu dropdown-content z-[1] bg-base-200 rounded-box w-52">
        <#slot />
      </ul>
    </details>
    """
  end
end
