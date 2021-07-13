defmodule BanchanWeb.StudioLive.Index do
  @moduledoc """
  Listing of studios belonging to the current user
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket, false)
    studios = Studios.list_studios()
    {:ok, assign(socket, studios: studios)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1>Studios</h1>
      <ul class="studios">
        {#for studio <- @studios}
          <li><LiveRedirect to={Routes.studio_show_path(Endpoint, :show, studio.slug)}>{studio.name}</LiveRedirect>: {studio.description}</li>
        {/for}
      </ul>
    </Layout>
    """
  end
end
