defmodule BanchanWeb.Components.Nav do
  @moduledoc """
  Handles session-related top menu items.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Notifications
  alias BanchanWeb.Endpoint

  prop current_user, :any
  prop uri, :string, required: true

  def render(assigns) do
    ~F"""
    <nav id="nav" class="navbar bg-base-100" role="navigation" aria-label="main navigation">
      <div class="flex-none gap-4 lg:hidden items-center">
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

      <div class="flex-1 font-semibold">
        <LiveRedirect to={Routes.home_path(Endpoint, :index)}>
          <img
            src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
            class="inline-block object-scale-down h-12 p-1 rounded-full"
          /> Banchan Art
        </LiveRedirect>
      </div>

      {#if is_nil(@current_user)}
        <div class="mx-4">
          <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
            <span>
              <i class="fa fa-sign-in-alt" />
              Log in
            </span>
          </LiveRedirect>
        </div>
      {/if}

      {#if @current_user}
        <div class="flex-none">
          <Notifications id="notifications" uri={@uri} current_user={@current_user} />
        </div>
      {/if}
    </nav>
    """
  end
end
