defmodule BanchanWeb.DenizenLive.Edit do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts
  alias BanchanWeb.Components.{Layout, ProfileEditor}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Accounts.get_user_by_handle!(handle)
    {:ok, assign(socket, user: user, changeset: User.profile_changeset(user))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      Editing profile for {@user.handle}
      <ProfileEditor for={@changeset} fields={[:handle, :name, :bio]} change="change" submit="submit" />
    </Layout>
    """
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.user
      |> User.profile_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Accounts.update_user_profile(socket.assigns.user, val["user"]) do
      {:ok, user} ->
        socket = assign(socket, changeset: User.profile_changeset(user), user: user)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_redirect(socket, to: Routes.denizen_show_path(Endpoint, :show, user.handle))}

      other ->
        other
    end
  end
end
