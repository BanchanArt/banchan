defmodule BanchanWeb.DiscoverLive.Index do
  @moduledoc """
  Banchan discovery page.
  """
  use BanchanWeb, :surface_view

  alias BanchanWeb.Components.Layout

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
    </Layout>
    """
  end
end
