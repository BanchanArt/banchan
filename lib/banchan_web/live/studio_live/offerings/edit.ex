defmodule BanchanWeb.StudioLive.Offerings.Edit do
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
  def mount(%{"offering_type" => offering_type} = params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, true)
    offering = Offerings.get_offering_by_type!(offering_type)
    changeset = Offering.changeset(offering, %{})

    {:ok, assign(socket, offering: offering, changeset: changeset)}
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
    >
      <h1>Edit Offering</h1>
      <Components.Offering id="edit-offering" changeset={@changeset} submit="save" />
    </Components.StudioLayout>
    """
  end

  @impl true
  def handle_info({"save", offering}, socket) do
    case Offerings.update_offering(socket.assigns.offering, offering) do
      # TODO: Redirect to the new offering itself.
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
