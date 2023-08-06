defmodule BanchanWeb.StudioLive.Offerings.New do
  @moduledoc """
  LiveView for creating new studio offerings.
  """
  use BanchanWeb, :live_view

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.Layout

  alias BanchanWeb.StudioLive.Components.Offering

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    {:ok, socket |> assign(gallery_images: nil)}
  end

  def handle_info({:updated_gallery_images, _, images}, socket) do
    {:noreply,
     socket
     |> assign(gallery_images: images)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} studio={@studio} context={:studio}>
      <div>
        <div class="p-6 max-w-lg mx-auto">
          <h1 class="text-3xl">New Offering</h1>
          <div class="divider" />
          <Offering
            id="new-offering"
            current_user={@current_user}
            current_user_member?={@current_user_member?}
            studio={@studio}
            gallery_images={@gallery_images}
          />
        </div>
      </div>
    </Layout>
    """
  end
end
