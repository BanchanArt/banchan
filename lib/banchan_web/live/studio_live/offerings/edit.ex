defmodule BanchanWeb.StudioLive.Offerings.Edit do
  @moduledoc """
  LiveView for creating new studio offerings.
  """
  use BanchanWeb, :live_view

  alias Banchan.Offerings

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.Layout

  alias BanchanWeb.StudioLive.Components.Offering

  @impl true
  def mount(%{"offering_type" => offering_type} = params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    offering =
      Offerings.get_offering_by_type!(
        socket.assigns.current_user,
        socket.assigns.studio,
        offering_type
      )

    {:ok, assign(socket, offering: offering)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} studio={@studio} context={:studio}>
      <div>
        <div class="p-6 max-w-lg mx-auto">
          <h1 class="text-3xl">Edit Offering</h1>
          <div class="divider" />
          <Offering
            id="edit-offering"
            current_user={@current_user}
            current_user_member?={@current_user_member?}
            studio={@studio}
            offering={@offering}
          />
        </div>
      </div>
    </Layout>
    """
  end
end
