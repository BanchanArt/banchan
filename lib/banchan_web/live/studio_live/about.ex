defmodule BanchanWeb.StudioLive.About do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias BanchanWeb.Components.Markdown

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
    <StudioLayout flash={@flash} id="studio-layout" studio={@studio} tab={:about}>
      <div class="w-full mx-auto md:bg-base-300">
        <div class="max-w-prose w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Markdown content={@studio.about} />
        </div>
      </div>
    </StudioLayout>
    """
  end
end
