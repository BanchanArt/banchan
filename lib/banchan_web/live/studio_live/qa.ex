defmodule BanchanWeb.StudioLive.Qa do
  @moduledoc """
  LiveView for Studio Q&A tab in studio pages.
  """
  use BanchanWeb, :surface_view

  alias BanchanWeb.StudioLive.Components.StudioLayout
  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(session, socket, false)
    socket = assign_studio_defaults(params, socket, false, false)
    {:ok, socket}
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
    >
      Q&A goes here
    </StudioLayout>
    """
  end
end
