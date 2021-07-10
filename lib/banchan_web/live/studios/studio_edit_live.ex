defmodule BanchanWeb.StudioEditLive do
  @moduledoc """
  Banchan studio profile viewing and editing.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias BanchanWeb.Components.{Layout, ProfileEditor}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket)
    studio = Studios.get_studio_by_slug!(slug)

    if Studios.is_user_in_studio(socket.assigns.current_user, studio)  do
      {:ok, assign(socket, studio: studio, changeset: Studio.changeset(studio, %{}))}
    else
      socket = put_flash(socket, :error, "Access denied")
      {:ok, push_redirect(socket, to: Routes.studio_show_path(Endpoint, :show, studio.slug))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      Editing Studio profile for {@studio.name}
      <ProfileEditor for={@changeset} fields={[:name, :slug, :description]} change="change" submit="submit" />
    </Layout>
    """
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.studio
      |> Studio.changeset(val["studio"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Studios.update_studio_profile(socket.assigns.studio, val["studio"]) do
      {:ok, studio} ->
        socket = assign(socket, changeset: Studio.changeset(studio, %{}), studio: studio)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_redirect(socket,
           to: Routes.studio_show_path(Endpoint, :show, studio.slug)
         )}

      other ->
        other
    end
  end
end
