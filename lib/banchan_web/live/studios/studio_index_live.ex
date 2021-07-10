defmodule BanchanWeb.StudioIndexLive do
  @moduledoc """
  Listing of studios that can be commissioned.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LivePatch

  alias Banchan.Studios
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    studios = Studios.list_studios()
    {:ok, assign(socket, studios: studios)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1>Commission a Studio</h1>
      <ul class="studios">
        {#for studio <- @studios}
        <li><LivePatch to={Routes.studio_view_path(Endpoint, :show, studio.slug)}>{studio.name}</LivePatch>: {studio.description}</li>
        {#else}
        You have no studios. <LivePatch to={Routes.studio_new_path(Endpoint, :new)}>Create one</LivePatch>.
        {/for}
      </ul>
    </Layout>
    """
  end
end
