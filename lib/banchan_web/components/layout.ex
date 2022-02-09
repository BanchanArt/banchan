defmodule BanchanWeb.Components.Layout do
  @moduledoc """
  Standard dynamic part of the layout used for Surface LiveViews.

  We can't have these just in the layout itself because of the dynamic bits.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.{Flash, Nav}

  prop current_user, :any
  prop flashes, :string

  slot hero
  slot default

  def render(assigns) do
    ~F"""
    <Nav current_user={@current_user} />
    {#if slot_assigned?(:hero)}
      <#slot name="hero" />
    {/if}
    <section class="section md:container md:mx-auto px-6 h-full">
      <Flash flashes={@flashes} />
      <#slot />
    </section>
    <footer class="footer mt-12 bottom-0 footer-center md:container md:mx-auto px-6">
      <div class="text-neutral-content bg-neutral rounded-lg min-w-full py-6">
        <h1
          x-data="{ message: '❤️ Alpine + TailwindCSS + DaisyUI + Phoenix + SurfaceUI' }"
          x-text="message"
          phx-update="ignore"
          id="supportFooter"
        />
        <p>
          Copyright © 2022 - All right reserved by <a href="https://www.dwg.dev/" class="link link-accent">DWG LLC</a>.
        </p>
      </div>
    </footer>
    """
  end
end
