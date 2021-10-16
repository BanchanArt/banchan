defmodule BanchanWeb.Components.Card do
  @moduledoc """
  Generic (Bulma) card component.
  """
  use BanchanWeb, :component

  @doc "Additional class text"
  prop class, :string, default: ""

  @doc "The header"
  slot header

  @doc "Right-aligned extra header content"
  slot header_aside

  @doc "The footer"
  slot footer

  @doc "The image"
  slot image

  @doc "The main content"
  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class={"inline-block max-w-md #{@class}"}>
      {#if slot_assigned?(:header)}
        <header class="">
            <#slot name="header" />
            <#slot name="header_aside" />
        </header>
      {/if}
      {#if slot_assigned?(:image)}
        <div class="object-scale-down max-w-md">
          <#slot name="image" />
        </div>
      {/if}
      <div class="max-w-prose">
        <#slot />
      </div>
      {#if slot_assigned?(:footer)}
        <footer class="bg-primary-600">
          <#slot name="footer" />
        </footer>
      {/if}
    </div>
    """
  end
end
