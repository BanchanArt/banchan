defmodule BanchanWeb.Components.Nav do
  @moduledoc """
  Handles session-related top menu items.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Endpoint

  prop current_user, :any

  def render(assigns) do
    ~F"""
    <nav
      id="nav"
      class="navbar bg-neutral text-neutral-content"
      role="navigation"
      aria-label="main navigation"
    >
      <div class="flex-1">
        <a href="/">
          <img
            src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
            class="inline-block object-scale-down h-12 p-1 rounded-full"
          /> Banchan Art
        </a>
      </div>

      <div class="flex-none hidden md:block">
        <ul class="menu horizontal">
          {#if @current_user}
            <li>
              <LiveRedirect to={Routes.commission_path(Endpoint, :index)}>
                <span>
                  <i class="fa fa-palette" />
                  Commissions
                </span>
              </LiveRedirect>
            </li>
          {#else}
            <li>
              <LiveRedirect label="Register" to={Routes.register_path(Endpoint, :new)}>
                <span>
                  <i class="fa fa-user" />
                  Register
                </span>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
                <span>
                  <i class="fa fa-sign-in-alt" />
                  Log in
                </span>
              </LiveRedirect>
            </li>
          {/if}
        </ul>
      </div>

      <div class="flex-none gap-4 items-center">
        <label for="drawer-toggle" class="btn btn-square btn-ghost">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            class="inline-block w-6 h-6 stroke-current"
          ><path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 6h16M4 12h16M4 18h16"
            /></svg>
        </label>
      </div>
    </nav>
    """
  end
end
