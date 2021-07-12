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
    <ul class="nav">
      {#if @current_user}
        <li><LiveRedirect label="Home" to={Routes.home_path(Endpoint, :index)} /></li>
        <li><LiveRedirect label={@current_user.email} to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)} /></li>
        <li><LiveRedirect label="Dashboard" to={Routes.dashboard_path(Endpoint, :index)} /></li>
        <li><LiveRedirect label="Your Studios" to={Routes.studio_index_path(Endpoint, :index)} /></li>
        <li><LiveRedirect label="Settings" to={Routes.settings_path(Endpoint, :edit)} /></li>
        <li><Link label="Log out" to={Routes.user_session_path(Endpoint, :delete)} method={:delete} /></li>
      {#else}
        <li><LiveRedirect label="Register" to={Routes.register_path(Endpoint, :new)} /></li>
        <li><LiveRedirect label="Log in" to={Routes.login_path(Endpoint, :new)} /></li>
      {/if}
    </ul>
    """
  end
end
