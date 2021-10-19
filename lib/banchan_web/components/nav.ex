defmodule BanchanWeb.Components.Nav do
  @moduledoc """
  Handles session-related top menu items.
  """
  use BanchanWeb, :component

  alias Surface.Components.{Link, LiveRedirect}

  alias BanchanWeb.Endpoint

  prop current_user, :any

  def render(assigns) do
    ~F"""
    <nav
      id="nav"
      class="bg-gradient-to-r from-primary-300 to-primary-500 align-top w-full leading-snug m-0 p-0"
      role="navigation"
      aria-label="main navigation"
    >
      <div class="md:container md:mx-auto text-white flex items-center gap-12 justify-start">
        <a href="/">
          <img
            src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
            class="inline-block object-scale-down h-12 p-1 rounded-full"
          /> Banchan Art
        </a>
        {#if @current_user}
          <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)}>
            <span>
              <i class="fa fa-user" /> @{@current_user.handle}
            </span>
          </LiveRedirect>
          <LiveRedirect to={Routes.dashboard_path(Endpoint, :index)}>
            <span>
              <i class="fa fa-palette" /> Dashboard
            </span>
          </LiveRedirect>
          <LiveRedirect to={Routes.studio_index_path(Endpoint, :index)}>
            <span>
              <i class="fa fa-palette" /> Studios
            </span>
          </LiveRedirect>
          <LiveRedirect to={Routes.settings_path(Endpoint, :edit)}>
            <span>
              <i class="fa fa-cog" /> Settings
            </span>
          </LiveRedirect>
          <Link to={Routes.user_session_path(Endpoint, :delete)} method={:delete}>
            <span>
              <i class="fa fa-sign-out-alt" /> Log out
            </span>
          </Link>
        {#else}
          <LiveRedirect label="Register" to={Routes.register_path(Endpoint, :new)}>
            <span>
              <i class="fa fa-user" /> Register
            </span>
          </LiveRedirect>
          <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
            <span>
              <i class="fa fa-sign-in-alt" /> Log in
            </span>
          </LiveRedirect>
        {/if}
      </div>
    </nav>
    """
  end
end
