defmodule BanchanWeb.HomeLive do
  @moduledoc """
  Banchan Homepage
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios
  alias BanchanWeb.Components.{Layout, StudioCard}

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket, false)
    studios = Studios.list_studios()
    {:ok, assign(socket, :studios, studios)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="title text-xl">Home</h1>
      <h2 class="subtitle">Commission Someone</h2>
      <div class="studio-list grid grid-cols-3 gap-3">
        {#for studio <- @studios}
          <div class="md:inline-grid max-w-md bg-primary-100 p-1 shadow-md">
            <StudioCard studio={studio} />
          </div>
        {/for}
      </div>
    </Layout>
    """
  end
end
