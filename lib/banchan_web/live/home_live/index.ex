defmodule BanchanWeb.HomeLive do
  @moduledoc """
  Banchan Homepage
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.StudioLive.Components.OfferingCard

  @impl true
  def mount(_params, _session, socket) do
    offerings =
      Offerings.list_offerings(
        current_user: socket.assigns.current_user,
        page_size: 24,
        order_by: :featured
      )

    {:ok, assign(socket, :offerings, offerings)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <h1 class="text-3xl">Featured Art Commissions</h1>
      <div class="divider" />
      <div class="p-2 text-xl">
        Featured Commission Offerings
        (<a href="#" class="link text-primary">Discover more...</a>):
      </div>
      <div class="pt-4 sm:px-2 flex flex-col gap-4">
        <div class="grid grid-cols-2 sm:gap-2 sm:grid-cols-3 md:grid-cols-4 auto-rows-fr">
          {#for {offering, idx} <- Enum.with_index(@offerings.entries)}
            <OfferingCard id={"offering-#{idx}"} current_user={@current_user} offering={offering} />
          {/for}
        </div>
      </div>
    </Layout>
    """
  end
end
