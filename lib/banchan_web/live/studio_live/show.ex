defmodule BanchanWeb.StudioLive.Show do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket, false)
    studio = Studios.get_studio_by_slug!(slug)
    members = Studios.list_studio_members(studio)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio(socket.assigns.current_user, studio)

    {:ok,
     assign(socket, studio: studio, members: members, current_user_member?: current_user_member?)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <div class="studio">
        <h1 class="title">{@studio.name}</h1>
        <h2 class="subtitle">{@studio.description}</h2>
      </div>
      {#if @current_user_member?}
        <LiveRedirect label="Edit" to={Routes.studio_edit_path(Endpoint, :edit, @studio.slug)} />
      {/if}

      <h2 class="subtitle">Members</h2>
      <ul class="studio-members">
        {#for member <- @members}
          <li><LiveRedirect label={member.name} to={Routes.denizen_show_path(Endpoint, :show, member.handle)} /></li>
        {/for}
      </ul>
    </Layout>
    """
  end
end
