defmodule BanchanWeb.StudioShowLive do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket)
    studio = Studios.get_studio_by_slug!(slug)
    {:ok, assign(socket, studio: studio)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <div class="studio">
        <h1>{@studio.name}</h1>
        <p>{@studio.description}</p>
      </div>
      <LiveRedirect label="Edit" to={Routes.studio_edit_path(Endpoint, :edit, @studio.slug)} />
    </Layout>
    """
  end
end
