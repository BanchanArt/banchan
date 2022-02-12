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
    <div class="flex flex-col h-screen">
      <Nav current_user={@current_user} />
      {#if slot_assigned?(:hero)}
        <#slot name="hero" />
      {/if}
      <section class="section md:container md:mx-auto px-6 flex-grow">
        <Flash flashes={@flashes} />
        <#slot />
      </section>
      <footer class="footer mt-6 bottom-0 footer-center md:mx-auto">
        <div class="text-primary-content bg-primary min-w-full pb-12 pt-6">
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
    </div>
    """
  end
end
