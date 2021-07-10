defmodule BanchanWeb.StudioIndexLive do
  @moduledoc """
  Listing of studios that can be commissioned.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    studios = Studios.list_studios_for_user(socket.assigns.current_user)
    {:ok, assign(socket, studios: studios)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1>Your Studios</h1>
      <ul class="studios">
        {#for studio <- @studios}
        <li><LiveRedirect to={Routes.studio_show_path(Endpoint, :show, studio.slug)}>{studio.name}</LiveRedirect>: {studio.description}</li>
        {#else}
        You have no studios. <LiveRedirect to={Routes.studio_new_path(Endpoint, :new)}>Create one</LiveRedirect>.
        {/for}
      </ul>
    </Layout>
    """
  end
end
