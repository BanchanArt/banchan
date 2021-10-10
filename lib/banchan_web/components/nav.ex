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
      <div class="md:container md:mx-auto">
        <a class="navbar-item text-white" href="/">
          <img
            src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
            class="inline-block object-scale-down h-12 p-1"
          /> Banchan Art
        </a>
        {#if @current_user}
          <LiveRedirect
            class="navbar-item md:mx-8 text-white"
            to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)}
          >
            <span class="icon-text">
              <span class="icon"><i class="fa fa-user" /></span>
              <span>@{@current_user.handle}</span>
            </span>
          </LiveRedirect>
          <LiveRedirect class="navbar-item md:mx-8 text-white" to={Routes.dashboard_path(Endpoint, :index)}>
            <span class="icon-text">
              <span class="icon"><i class="fa fa-palette" /></span>
              <span>Dashboard</span>
            </span>
          </LiveRedirect>
          <LiveRedirect
            class="navbar-item md:mx-8 text-white"
            to={Routes.studio_index_path(Endpoint, :index)}
          >
            <span class="icon-text">
              <span class="icon"><i class="fa fa-palette" /></span>
              <span>Studios</span>
            </span>
          </LiveRedirect>
          <LiveRedirect class="navbar-item md:mx-8 text-white" to={Routes.settings_path(Endpoint, :edit)}>
            <span class="icon-text">
              <span class="icon"><i class="fa fa-cog" /></span>
              <span>Settings</span>
            </span>
          </LiveRedirect>
          <Link
            class="navbar-item md:mx-8 text-white"
            to={Routes.user_session_path(Endpoint, :delete)}
            method={:delete}
          >
            <span class="icon-text">
              <span class="icon"><i class="fa fa-sign-out-alt" /></span>
              <span>Log out</span>
            </span>
          </Link>
        {#else}
          <LiveRedirect
            class="navbar-item md:mx-8 text-white"
            label="Register"
            to={Routes.register_path(Endpoint, :new)}
          >
            <span class="icon-text">
              <span class="icon"><i class="fa fa-user" /></span>
              <span>Register</span>
            </span>
          </LiveRedirect>
          <LiveRedirect class="navbar-item md:mx-8 text-white" to={Routes.login_path(Endpoint, :new)}>
            <span class="icon-text">
              <span class="icon"><i class="fa fa-sign-in-alt" /></span>
              <span>Log in</span>
            </span>
          </LiveRedirect>
        {/if}
      </div>
    </nav>
    """
  end
end
