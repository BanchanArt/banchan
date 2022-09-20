defmodule BanchanWeb.StudioLive.Offerings.New do
  @moduledoc """
  LiveView for creating new studio offerings.
  """
  use BanchanWeb, :surface_view

  alias BanchanWeb.StudioLive.Components

  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    {:ok, socket |> assign(gallery_images: nil)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  def handle_info({:updated_gallery_images, _, images}, socket) do
    {:noreply,
     socket
     |> assign(gallery_images: images)}
  end

  def handle_info(%{event: "follower_count_changed", payload: new_count}, socket) do
    {:noreply, socket |> Context.put(follower_count: new_count)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Components.StudioLayout
      id="studio-layout"
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:shop}
      uri={@uri}
    >
      <div>
        <div class="p-6 max-w-lg mx-auto">
          <h1 class="text-3xl">New Offering</h1>
          <div class="divider" />
          <Components.Offering
            id="new-offering"
            current_user={@current_user}
            current_user_member?={@current_user_member?}
            studio={@studio}
            gallery_images={@gallery_images}
          />
        </div>
      </div>
    </Components.StudioLayout>
    """
  end
end
