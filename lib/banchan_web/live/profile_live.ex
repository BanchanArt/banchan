defmodule BanchanWeb.ProfileLive do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts

  alias BanchanWeb.Components.Layout

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Accounts.get_user_by_handle!(handle)
    {:ok, assign(socket, user: user)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      {#if @live_action == :index}
      Profile page for {@user}
      {#else if @live_action == :edit && @user.id == @current_user.id}
      Editing profile for {@user}
      {/if}
    </Layout>
    """
  end
end
