defmodule BanchanWeb.Components.Card do
  @moduledoc """
  Generic card component.
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
    <div class="shadow-lg bg-base-200 card card-bordered">
      <div class={"inline-block card-body #{@class}"}>
        {#if slot_assigned?(:header)}
          <header class="container">
            <#slot name="header" />
            {#if slot_assigned?(:header_aside)}
              <span class="float-right">
                <#slot name="header_aside" />
              </span>
            {/if}
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
          <footer>
            <#slot name="footer" />
          </footer>
        {/if}
      </div>
    </div>
    """
  end
end
