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
        <div class="hero-head">

        </div>
        <div class="hero-body">
          <article class="media">
            <figure class="image is-48x48 media-left">
              <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
            </figure>
            <div class="media-content">
              <h1 class = "title"> {@user.handle} </h1>
              <p class = "subtitle"> Witty phrase here. </p>
            </div>
            <div class="media-right">
              <a class="button is-warning">Follow</a>
            </div>
          </article>

        </div>
        <div class="hero-foot">

          <nav class="tabs is-boxed is-right">
            <div class="container">
              <ul>
                <li class="is-active">
                  <a> Profile Home </a>
                </li>
                <li> <a>Featured</a> </li>
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
            <div class="columns denizen-studios is-multiline block">
              {#for studio <- @studios}
                <div class="column">
                  <StudioCard studio={studio} />
                </div>
              {/for}
            </div>
          </div>
          <div class="tile is-child notification is-warning block">
            <h2 class="title"> About {@user.handle} </h2>
            <figure class="image is-3by1" alt="denizen ID">
              <img src="https://bulma.io/images/placeholders/640x480.png">
            </figure>
            <div class="content">
              <p class="">Name: {@user.name}</p>
              <p class="">Bio: {@user.bio}</p>
                {#if @current_user && @current_user.id == @user.id}
                  <LiveRedirect label="Edit" to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)} class="button is-primary is-fullwidth"/>
                {/if}
            </div>
          </div>

        </div>
        <div class="tile">

        </div>

      </div>


    </Layout>
    """
  end
end
