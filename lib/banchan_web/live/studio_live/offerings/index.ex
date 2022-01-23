defmodule BanchanWeb.StudioLive.Offerings.Index do
  @moduledoc """
  LiveView for viewing individual studio offerings.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.StudioLayout
  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, true)
    offerings = Studios.list_studio_offerings(socket.assigns.studio)

    {:ok, assign(socket, offerings: offerings)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout current_user={@current_user} flashes={@flash} studio={@studio} current_user_member?={@current_user_member?} tab={:settings}>
      <h1>Offerings</h1>
      <h2>Add/remove/edit offerings for your studio here</h2>
      <LiveRedirect label="New Offering" to={Routes.studio_offerings_new_path(Endpoint, :new, @studio.handle)} />
      <table class="table w-full table-compact">
        <thead>
          <tr>
            <th>
              <label>
                Select
              </label>
            </th>
            <th>Name</th>
            <th>Description</th>
            <th>Status</th>
            <th>Base Price</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {#for offering <- @offerings}
          <tr>
            <th>
              <label>
                <input type="checkbox" class="checkbox">
              </label>
            </th>
            <td>{offering.name}</td>
            <td>{offering.description}</td>
            <td>
            {#if offering.open}
            Open
            {#else}
            Closed
            {/if}
            </td>
            <td>{offering.base_price || "Inquire"}</td>
            <th>
              <button class="btn btn-secondary btn-xs"><a href={Routes.studio_offerings_edit_path(Endpoint, :edit, @studio.handle, offering.type)} class="link">Edit</a></button>
            </th>
          </tr>
          {/for}
        </tbody>
        <tfoot>
          <tr>
            <th />
            <th>Name</th>
            <th>Description</th>
            <th>Status</th>
            <th>Base Price</th>
            <th />
          </tr>
        </tfoot>
      </table>
    </StudioLayout>
    """
  end
end
