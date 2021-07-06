defmodule BanchanWeb.StudioIndexLive do
  @moduledoc """
  Listing of studios belonging to the current user.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Link

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
        <li><Link to={Routes.studio_view_path(Endpoint, :show, studio.slug)}>{studio.name}</Link>: {studio.description}</li>
        {#else}
        You have no studios. <Link to={Routes.studio_new_path(Endpoint, :new)}>Create one</Link>.
        {/for}
      </ul>
    </Layout>
    """
  end
end
