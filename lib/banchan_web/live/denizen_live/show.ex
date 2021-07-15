defmodule BanchanWeb.DenizenLive.Show do
  @moduledoc """
  Banchan denizen profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Accounts
  alias Banchan.Studios
  alias BanchanWeb.Components.{Layout, StudioCard}
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
      {#if @current_user && @current_user.id == @user.id}
        <LiveRedirect label="Edit" to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)} />
      {/if}
      <h2 class="title">Studios</h2>
      <div class="columns denizen-studios is-multiline">
        {#for studio <- @studios}
          <div class="column is-one-quarter">
            <StudioCard studio={studio} />
          </div>
        {/for}
      </div>
    </Layout>
    """
  end
end
