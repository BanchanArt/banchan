defmodule BanchanWeb.HomeLive do
  @moduledoc """
  Banchan Homepage
  """
  use BanchanWeb, :surface_view

  alias Banchan.Components.{Flash, Session}

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, assign(socket, query: "", results: %{})}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Session current_user={@current_user} />
    <main role="main" class="container">
      <Flash flashes={@flash} />

      I guess I'm home?
    </main>
    """
  end
end
