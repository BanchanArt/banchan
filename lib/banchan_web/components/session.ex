defmodule Banchan.Components.Session do
  @moduledoc """
  Handles session-related top menu items.
  """
  use BanchanWeb, :component

  alias Surface.Components.Link

  prop current_user, :any

  def render(assigns) do
    ~F"""
    <ul>
      {#if @current_user}
        <li>{@current_user.email}</li>
        <li><Link label="Settings" to={Routes.user_settings_path(BanchanWeb.Endpoint, :edit)} /></li>
        <li><Link label="Log out" to={Routes.user_session_path(BanchanWeb.Endpoint, :delete)} method={:delete} /></li>
      {#else}
        <li><Link label="Register" to={Routes.user_registration_path(BanchanWeb.Endpoint, :new)} /></li>
        <li><Link label="Log in" to={Routes.user_session_path(BanchanWeb.Endpoint, :new)} /></li>
      {/if}
    </ul>
    """
  end
end
