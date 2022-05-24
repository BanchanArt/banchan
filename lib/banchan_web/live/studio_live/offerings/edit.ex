defmodule BanchanWeb.StudioLive.Offerings.Edit do
  @moduledoc """
  LiveView for creating new studio offerings.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings
  alias Banchan.Offerings.Offering

  alias BanchanWeb.CommissionLive.Components
  alias BanchanWeb.Endpoint
  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(%{"offering_type" => offering_type} = params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)
    offering = Offerings.get_offering_by_type!(offering_type, socket.assigns.current_user_member?)
    changeset = Offering.changeset(offering, %{})

    {:ok, assign(socket, offering: offering, changeset: changeset)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:ok, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Components.StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:settings}
      uri={@uri}
    >
      <div class="shadow bg-base-200 text-base-content">
        <div class="p-6">
          <h1>Edit Offering</h1>
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
           to: Routes.studio_offerings_index_path(Endpoint, :index, socket.assigns.studio.handle)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
