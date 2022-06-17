defmodule BanchanWeb.StudioLive.Offerings.Edit do
  @moduledoc """
  LiveView for creating new studio offerings.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings
  alias Banchan.Offerings.Offering

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components

  @impl true
  def mount(%{"offering_type" => offering_type} = params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)
    offering = Offerings.get_offering_by_type!(offering_type, socket.assigns.current_user_member?)
    changeset = Offering.changeset(offering, %{})

    {:ok, assign(socket, offering: offering, changeset: changeset)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
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
          <h1 class="text-3xl">Edit Offering</h1>
          <div class="divider" />
          <Components.Offering id="edit-offering" changeset={@changeset} submit="save" />
        </div>
      </div>
    </Components.StudioLayout>
    """
  end

  @impl true
  def handle_info({"save", offering}, socket) do
    case Offerings.update_offering(
           socket.assigns.offering,
           socket.assigns.current_user_member?,
           offering
         ) do
      {:ok, _offering} ->
        put_flash(socket, :info, "Offering updated")

        {:noreply,
         redirect(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
