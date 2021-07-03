defmodule BanchanWeb.StudioLive do
  @moduledoc """
  Banchan studio profile viewing and editing.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios

  alias BanchanWeb.Components.Layout

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket)
    studio = Studios.get_studio_by_slug!(slug)
    {:ok, assign(socket, studio: studio)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      {#if @live_action == :index}
      Profile page for {@studio}
      {#else if @live_action == :edit && @studio.user_id == @current_user.id}
      Editing profile for {@studio}
      {/if}
    </Layout>
    """
  end
end
