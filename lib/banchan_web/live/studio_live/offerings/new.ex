defmodule BanchanWeb.StudioLive.Offerings.New do
  @moduledoc """
  LiveView for creating new studio offerings.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings
  alias Banchan.Offerings.Offering

  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components

  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)
    changeset = Offering.changeset(%Offering{}, %{})

    {:ok, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_info({"save", offering, image}, socket) do
    case Offerings.new_offering(
           socket.assigns.studio,
           socket.assigns.current_user_member?,
           offering,
           image
         ) do
      {:ok, _offering} ->
        put_flash(socket, :info, "Offering created.")

        {:noreply,
         redirect(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
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
      tab={:settings}
      uri={@uri}
    >
      <div>
        <div class="p-6 max-w-lg mx-auto">
          <h1 class="text-3xl">New Offering</h1>
          <div class="divider" />
          <Components.Offering
            id="new-offering"
            current_user={@current_user}
            changeset={@changeset}
            submit="save"
          />
        </div>
      </div>
    </Components.StudioLayout>
    """
  end
end
