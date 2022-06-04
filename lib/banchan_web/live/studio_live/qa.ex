defmodule BanchanWeb.StudioLive.Qa do
  @moduledoc """
  LiveView for Studio Q&A tab in studio pages.
  """
  use BanchanWeb, :surface_view

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.StudioLive.Components.StudioLayout

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:qa}
      uri={@uri}
    >
      Q&A goes here
    </StudioLayout>
    """
  end
end
