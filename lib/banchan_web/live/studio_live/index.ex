defmodule BanchanWeb.StudioLive.Index do
  @moduledoc """
  Listing of studios belonging to the current user
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.{Layout, StudioCard}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    studios = Studios.list_studios()
    {:ok, assign(socket, studios: studios)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Studios</h1>
      <LiveRedirect to={Routes.studio_new_path(Endpoint, :new)}>
        <h2 class="text-center btn btn-sm btn-primary rounded-full m-5">Create a new studio</h2>
      </LiveRedirect>
      <div class="studio-list grid grid-cols-3 gap-3">
        {#for studio <- @studios}
          <div class="md:inline-grid max-w-md bg-base-200 p-1 shadow-md">
            <StudioCard studio={studio} />
          </div>
        {/for}
      </div>
    </Layout>
    """
  end
end
