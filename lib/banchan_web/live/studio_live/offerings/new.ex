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
  def mount(params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, true)
    changeset = Offering.changeset(%Offering{}, %{})

    {:ok, assign(socket, changeset: changeset)}
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
      <div class="card shadow bg-base-200 card-bordered text-base-content lg:card-side">
        <div class="card-body">
          <div data-tip="Make a new offering to the gods" class="tooltip tooltip-open tooltip-bottom tooltip-primary">
            <h1 class="text-xl">New Offering</h1>
          </div>
          <Components.Offering id="new-offering" changeset={@changeset} submit="save" />
        </div>
      </div>

    </Components.StudioLayout>
    """
  end

  @impl true
  def handle_info({"save", offering}, socket) do
    case Offerings.new_offering(socket.assigns.studio, offering) do
      # TODO: Redirect to the new offering itself.
      {:ok, _offering} ->
        put_flash(socket, :info, "Offering created.")

        {:noreply,
         redirect(socket,
           to: Routes.studio_offerings_index_path(Endpoint, :index, socket.assigns.studio.handle)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
