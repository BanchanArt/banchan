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
        <li><LiveRedirect label={"@#{@current_user.handle}"} to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)} /></li>
        <li><Link label="Settings" to={Routes.user_settings_path(Endpoint, :edit)} /></li>
        <li><Link label="Log out" to={Routes.user_session_path(Endpoint, :delete)} method={:delete} /></li>
      {#else}
        <li><Link label="Register" to={Routes.user_registration_path(Endpoint, :new)} /></li>
        <li><Link label="Log in" to={Routes.user_session_path(Endpoint, :new)} /></li>
      {/if}
    </ul>
    """
  end
end
