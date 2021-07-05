defmodule BanchanWeb.StudioLive do
  @moduledoc """
  Banchan studio profile viewing and editing.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias BanchanWeb.Components.{Layout, ProfileEditor}

  @impl true
  def mount(params, session, socket) do
    {:noreply, socket} = handle_params(params, session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket)
    studio = Studios.get_studio_by_slug!(slug)
    {:noreply, assign(socket, studio: studio, changeset: Studio.changeset(studio, %{}))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      {#if @live_action == :show}
      Studio page for {@studio.name}
      {#elseif @live_action == :edit && @studio.user_id == @current_user.id}
      Studio profile for {@studio.name}
      <ProfileEditor for={@changeset} fields={[:slug, :name, :description]} change="change" submit="submit" />
      {#elseif @live_action == :edit}
      no
      {/if}
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
        put_flash(socket, :info, "Profile updated")
        {:noreply, push_patch(socket, to: Routes.studio_path(Endpoint, :edit, studio.slug))}

      other ->
        other
    end
  end
end
