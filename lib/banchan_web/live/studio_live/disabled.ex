defmodule BanchanWeb.StudioLive.Disabled do
  @moduledoc """
  LiveView people get redirected to when the studio is disabled.
  """
  use BanchanWeb, :live_view

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.StudioLive.Components.StudioLayout

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout flashes={@flash} id="studio-layout" studio={@studio}>
      <div class="w-full mx-auto md:bg-base-300">
        <div class="max-w-prose w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          This studio has been disabled by site administrators.
        </div>
      </div>
    </StudioLayout>
    """
  end
end
