defmodule BanchanWeb.Components.Card do
  @moduledoc """
  Generic card component.
  """
  use BanchanWeb, :component

  @doc "Additional class text"
  prop class, :css_class

  @doc "Class to apply to image"
  prop image_class, :css_class, default: "aspect-video"

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
    <bc-card class={
      "bg-base-200 card card-compact flex flex-col grow rounded-none group focus:outline-none focus:ring-0",
      @class
    }>
      {#if slot_assigned?(:image)}
        <figure class={@image_class, "rounded-none group-focus:ring-1 group-focus:ring-primary"}>
          <#slot {@image} />
        </figure>
      {/if}
      <div class="flex flex-col py-4 grow">
        {#if slot_assigned?(:header)}
          <header class="flex flex-row items-center px-4 card-title">
            <div class="grow">
              <#slot {@header} />
            </div>
            {#if slot_assigned?(:header_aside)}
              <#slot {@header_aside} />
            {/if}
          </header>
        {/if}
        <div class="flex flex-col grow default-slot">
          <#slot />
        </div>
        {#if slot_assigned?(:footer)}
          <footer class="justify-end card-actions">
            <#slot {@footer} />
          </footer>
        {/if}
      </div>
    </bc-card>
    """
  end
end
