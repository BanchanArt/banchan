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
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  def handle_info(%{event: "follower_count_changed", payload: new_count}, socket) do
    {:noreply, socket |> assign(followers: new_count)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      id="studio-layout"
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      followers={@followers}
      current_user_member?={@current_user_member?}
      tab={:about}
      uri={@uri}
    >
      <div class="w-full mx-auto md:bg-base-300">
        <div class="max-w-prose w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Markdown content={@studio.about} />
        </div>
      </div>
    </StudioLayout>
    """
  end
end
