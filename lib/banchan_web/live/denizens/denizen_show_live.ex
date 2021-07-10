defmodule BanchanWeb.DenizenShowLive do
  @moduledoc """
  Banchan denizen profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LivePatch

  alias Banchan.Accounts
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Accounts.get_user_by_handle!(handle)
    {:ok, assign(socket, user: user)}
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
      <LivePatch label="Edit" to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)} />
    </Layout>
    """
  end
end
