defmodule BanchanWeb.ProfileLive do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts.User
  alias Banchan.Repo

  alias BanchanWeb.Components.Layout

  @impl true
  def mount(%{"user" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Repo.get_by!(User, handle: handle)
    {:ok, assign(socket, query: "", results: %{}, user: user)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      Profile page for {@user}
    </Layout>
    """
  end
end
