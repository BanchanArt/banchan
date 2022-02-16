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
    <div class="flex flex-col h-screen justify-between">
      <Nav current_user={@current_user} />
      {#if slot_assigned?(:hero)}
        <#slot name="hero" />
      {/if}
      <section class="px-4 flex-grow">
        <Flash flashes={@flashes} />
        <#slot />
      </section>
      <footer class="footer p-10 bg-neutral text-neutral-content">
        <div>
          <span class="footer-title">Company</span>
          {!-- # TODO: Fill these out --}
          <a href="#" class="link link-hover">About us</a>
          <a href="#" class="link link-hover">Contact</a>
          <a href="#" class="link link-hover">Jobs</a>
          <a href="#" class="link link-hover">Press kit</a>
        </div>
        <div>
          {!-- # TODO: Fill these out --}
          <span class="footer-title">Legal</span>
          <a href="#" class="link link-hover">Terms of use</a>
          <a href="#" class="link link-hover">Privacy policy</a>
          <a href="#" class="link link-hover">Cookie policy</a>
        </div>
      </footer>
    </div>
    """
  end
end
