defmodule BanchanWeb.Components.Card do
  @moduledoc """
  Generic card component.
  """
  use BanchanWeb, :component

  @doc "Additional class text"
  prop class, :css_class

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
    <div class={"shadow-xl bg-base-200 card card-compact flex flex-col flex-grow", @class}>
      {#if slot_assigned?(:image)}
        <figure class="aspect-video">
          <#slot name="image" />
        </figure>
      {/if}
      <div class="card-body flex flex-col flex-grow">
        {#if slot_assigned?(:header)}
          <header class="card-title flex items-center">
            <div class="grow">
              <#slot name="header" />
            </div>
            {#if slot_assigned?(:header_aside)}
              <#slot name="header_aside" />
            {/if}
          </header>
        {/if}
        <div class="flex flex-col flex-grow p-4">
          <#slot />
        </div>
        {#if slot_assigned?(:footer)}
          <footer class="card-actions justify-end">
            <#slot name="footer" />
          </footer>
        {/if}
      </div>
    </div>
    """
  end
end
