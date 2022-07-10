defmodule BanchanWeb.StudioLive.Index do
  @moduledoc """
  Listing of studios belonging to the current user
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios
  alias BanchanWeb.Components.{Layout, StudioCard}

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
      <div class="studio-list grid grid-cols-2 sm:gap-2 md:grid-cols-4 auto-rows-fr">
        {#for studio <- @studios}
          <StudioCard studio={studio} />
        {/for}
      </div>
    </Layout>
    """
  end
end
