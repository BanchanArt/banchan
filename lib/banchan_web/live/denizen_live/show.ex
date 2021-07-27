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
      <section class="hero is-primary">
        <div class="hero-body">
          <h1 class = "title"> {@user.handle} </h1>
          <p class = "subtitle"> Witty phrase here. </p>
        </div>
        <div class="hero-foot">
          <nav class="tabs is-boxed is-right">
            <div class="container">
              <ul>
                <li class="is-active">
                  <a> Profile Home </a>
                </li>
                <li> <a>Featured</a> </li>
                <li> <a>Showcases</a> </li>
                <li> <a>Characters</a> </li>
              </ul>
            </div>
          </nav>
        </div>
      </section>

      <div class="tile is-ancester">
        <div class="tile is-parent is-12">
          <div class="tile is-child notification is-success">
            <h2 class="title">Studios</h2>
            <div class="columns denizen-studios is-multiline">
              {#for studio <- @studios}
                <div class="column">
                  <StudioCard studio={studio} />
                </div>
              {/for}
            </div>
          </div>
          <div class="tile is-child notification is-warning">
            <p class="title"> About {@user.handle} </p>
            <p>Name: {@user.name}</p>
            <p>Bio: {@user.bio}</p>
            <button>
              {#if @current_user && @current_user.id == @user.id}
                <LiveRedirect label="Edit" to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)} />
              {/if}
            </button>
          </div>

        </div>
        <div class="tile">

        </div>

      </div>


    </Layout>
    """
  end
end
