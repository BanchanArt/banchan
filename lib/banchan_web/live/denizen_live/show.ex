defmodule BanchanWeb.DenizenLive.Show do
  @moduledoc """
  Banchan denizen profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Accounts
  alias Banchan.Studios
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket, false)
    user = Accounts.get_user_by_handle!(handle)
    studios = Studios.list_studios_for_user(user)
    {:ok, assign(socket, user: user, studios: studios)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      Denizen Profile Page for {@user.handle}
      <div>
        <p>Name: {@user.name}</p>
        <p>Bio: {@user.bio}</p>
      </div>
      <LiveRedirect label="Edit" to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)} />
      <h2>Studios</h2>
      <ul class="denizen-studios">
        {#for studio <- @studios}
          <li><LiveRedirect label={studio.name} to={Routes.studio_show_path(Endpoint, :show, studio.slug)} /></li>
        {/for}
      </ul>
    </Layout>
    """
  end
end
