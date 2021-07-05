defmodule BanchanWeb.ProfileLive do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts
  alias BanchanWeb.Components.{Layout, ProfileEditor}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(params, session, socket) do
    {:noreply, socket} = handle_params(params, session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Accounts.get_user_by_handle!(handle)
    {:noreply, assign(socket, user: user, changeset: User.profile_changeset(user))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      {#if @live_action == :show}
      Profile page for {@user.handle}
      <div>
        <p>Name: {@user.name}</p>
        <p>Bio: {@user.bio}</p>
      </div>
      {#elseif @live_action == :edit && @user.id == @current_user.id}
      Editing profile for {@user.handle}
      <ProfileEditor for={@changeset} fields={[:handle, :name, :bio]} change="change" submit="submit" />
      {#else if @live_action == :edit}
      You can't edit someone else's profile.
      {/if}
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
        put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_patch(socket, replace: true, to: Routes.profile_path(Endpoint, :edit, user.handle))}

      other ->
        other
    end
  end
end
