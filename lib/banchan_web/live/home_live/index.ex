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
    offerings = Offerings.list_offerings(current_user: socket.assigns.current_user)
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
      <h1 class="text-3xl">Home</h1>
      <div class="sm:px-2 grid grid-cols-2 sm:gap-2 sm:grid-cols-3 md:grid-cols-4 auto-rows-fr">
        {#for {offering, idx} <- Enum.with_index(@offerings)}
          <OfferingCard id={"offering-#{idx}"} current_user={@current_user} offering={offering} />
        {/for}
      </div>
    </Layout>
    """
  end
end
