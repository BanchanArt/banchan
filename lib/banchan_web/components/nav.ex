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
      class="navbar is-primary"
      role="navigation"
      aria-label="main navigation"
      x-data="{ open: false }"
    >
      <div class="navbar-brand">
        <a class="navbar-item" href="/">
          <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
        </a>
        <a
          role="button"
          class="navbar-burger"
          aria-label="menu"
          aria-expanded="false"
          @click="open = !open"
        >
          <span aria-hidden="true" />
          <span aria-hidden="true" />
          <span aria-hidden="true" />
        </a>
      </div>
      <div :class="{ 'is-active': open }" class="navbar-menu">
        <div class="navbar-start">
          {#if @current_user}
            <LiveRedirect
              class="navbar-item"
              to={Routes.denizen_show_path(Endpoint, :show, @current_user.at.at)}
            >
              <span class="icon-text">
                <span class="icon"><i class="fa fa-user" /></span>
                <span>@{@current_user.at.at}</span>
              </span>
            </LiveRedirect>
            <LiveRedirect class="navbar-item" to={Routes.dashboard_path(Endpoint, :index)}>
              <span class="icon-text">
                <span class="icon"><i class="fa fa-palette" /></span>
                <span>Dashboard</span>
              </span>
            </LiveRedirect>
            <LiveRedirect class="navbar-item" to={Routes.studio_index_path(Endpoint, :index)}>
              <span class="icon-text">
                <span class="icon"><i class="fa fa-palette" /></span>
                <span>Studios</span>
              </span>
            </LiveRedirect>
            <LiveRedirect class="navbar-item" to={Routes.settings_path(Endpoint, :edit)}>
              <span class="icon-text">
                <span class="icon"><i class="fa fa-cog" /></span>
                <span>Settings</span>
              </span>
            </LiveRedirect>
            <Link class="navbar-item" to={Routes.user_session_path(Endpoint, :delete)} method={:delete}>
              <span class="icon-text">
                <span class="icon"><i class="fa fa-sign-out-alt" /></span>
                <span>Log out</span>
              </span>
            </Link>
          {#else}
            <LiveRedirect class="navbar-item" label="Register" to={Routes.register_path(Endpoint, :new)}>
              <span class="icon-text">
                <span class="icon"><i class="fa fa-user" /></span>
                <span>Register</span>
              </span>
            </LiveRedirect>
            <LiveRedirect class="navbar-item" to={Routes.login_path(Endpoint, :new)}>
              <span class="icon-text">
                <span class="icon"><i class="fa fa-sign-in-alt" /></span>
                <span>Log in</span>
              </span>
            </LiveRedirect>
          {/if}
        </div>
      </div>
    </nav>
    """
  end
end
