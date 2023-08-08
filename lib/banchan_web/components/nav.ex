defmodule BanchanWeb.Components.Nav do
  @moduledoc """
  Handles session-related top menu items.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Icon, Notifications}
  alias BanchanWeb.Endpoint

  prop current_user, :any, from_context: :current_user

  def render(assigns) do
    ~F"""
    <nav
      id="nav"
      class="border-b navbar bg-base-200 border-base-content border-opacity-10"
      role="navigation"
      aria-label="main navigation"
    >
      <div class="items-center flex-none gap-4 lg:hidden">
        <label for="drawer-toggle" class="btn btn-square btn-ghost">
          <Icon name="menu" size="6" />
        </label>
      </div>

      <div class="flex-1 font-semibold">
        <LiveRedirect to={Routes.home_path(Endpoint, :index)}>
          <div class="flex flex-row items-center gap-2">
            <img
              alt="Banchan Art logo"
              src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
              class="inline-block object-scale-down h-10 p-1 rounded-full"
            />
            <h1>Banchan Art</h1>
          </div>
        </LiveRedirect>
      </div>

      {#if is_nil(@current_user)}
        <div class="mx-4">
          <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
            <Icon name="log-in" size="4">Log in</Icon>
          </LiveRedirect>
        </div>
      {/if}

      {#if @current_user}
        <div class="flex-none">
          <Notifications id="notifications" />
        </div>
      {/if}
    </nav>
    """
  end
end
