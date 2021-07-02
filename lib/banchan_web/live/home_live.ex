defmodule BanchanWeb.HomeLive do
  @moduledoc """
  Banchan Homepage
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Link

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, assign(socket, query: "", results: %{})}
  end

  @impl true
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

    <main role="main" class="container">
      <p class="alert alert-info" role="alert"
          :on-click="lv:clear-flash"
          :values={key: "info"}>{live_flash(@flash, :info)}</p>

      <p class="alert alert-danger" role="alert"
          :on-click="lv:clear-flash"
          :values={key: "error"}>{live_flash(@flash, :error)}</p>
    </main>
    <div>and we're live!</div>
    """
  end
end
