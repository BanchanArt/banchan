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
      <section class="grid grid-cols-2 bg-teal-300">
        <div class="col-span-12">
          <article class="ml-8">
            <figure class="">
              <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
            </figure>
            <h1 class="text-xl text-white font-bold">
              {@user.handle}
            </h1>
            <br>
            <p class="text-base text-white">
              Witty phrase here.
            </p>
            <a class="bg-teal-400 text-center rounded-lg px-2 py-1 text-white">Follow</a>
          </article>
        </div>
        <nav class="col-start-2 grid-cols-3 inline-grid">
          <div class="bg-teal-200 text-center rounded-t-lg border-t-6 border-solid border-green-300 text-violet-400"><a>Profile Home</a></div>
          <div class="bg-teal-400 bg-opacity-60 text-center rounded-t-lg text-white"><a>Featured</a></div>
          <div class="bg-teal-400 bg-opacity-60 text-center rounded-t-lg text-white"><a>Characters</a></div>
        </nav>
      </section>
      <div class="grid grid-cols-2 justify-items-stretch gap-6">
        <div class="p-4 bg-amber-200">
          <h2 class="text-xl text-white font-bold">Studios</h2>
          <div class="denizen-studios">
            {#for studio <- @studios}
              <StudioCard studio={studio} />
            {/for}
          </div>
        </div>
        <div class="bg-purple-600 bg-opacity-20 p-4">
          <h2 class="text-xl text-white font-bold flex-grow">
            About {@user.handle}
          </h2>
          <figure class="" alt="denizen ID">
            <img src="https://bulma.io/images/placeholders/640x480.png">
          </figure>
          <div class="content">
            <p class="">Name: {@user.name}</p>
            <p class="">Bio: {@user.bio}</p>
            {#if @current_user && @current_user.id == @user.id}
              <LiveRedirect
                label="Edit"
                to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)}
                class="button is-primary is-fullwidth"
              />
            {/if}
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
