defmodule BanchanWeb.DenizenLive.Show do
  @moduledoc """
  Banchan denizen profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Accounts
  alias Banchan.Studios
  alias BanchanWeb.Components.{Avatar, Layout, StudioCard}
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
      <section class="grid grid-cols-2 bg-secondary">
        <div class="col-span-12">
          <article class="ml-8">
            <Avatar class="w-24 h-24" user={@user} />
            <h1 class="text-xl text-base-content font-bold">
              {@user.handle}
            </h1>
            <br>
            <p class="text-base text-secondary-content">
              Witty phrase here.
            </p>
            {!-- TODO: add in follow functionality --}
            <a href="/" class="btn glass btn-sm text-center rounded-full px-4 py-0" label="Follow">Follow</a>
          </article>
        </div>
        <nav class="tabs col-start-2 grid-cols-3 inline-grid">
          <div class="tab tab-bordered tab-active bg-primary-focus text-center rounded-t-lg border-t-6 border-solid border-green-300"><a>Profile Home</a></div>
          <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Featured</a></div>
          <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Characters</a></div>
        </nav>
      </section>
      <div class="grid grid-cols-2 justify-items-stretch gap-6 mt-8">
        <div class="bg-base-200 p-4 shadow-lg">
          <h2 class="text-xl text-secondary-content font-bold">Studios</h2>
          <div class="denizen-studios">
            {#for studio <- @studios}
              <StudioCard studio={studio} />
            {/for}
          </div>
        </div>
        <div class="bg-base-200 p-4 shadow-lg">
          <h2 class="text-xl text-secondary-content font-bold flex-grow">
            About {@user.handle}
          </h2>
          <figure alt="denizen ID">
            <Avatar class="w-10" user={@user} />
          </figure>
          <div class="content">
            <p class="">Name: {@user.name}</p>
            <p class="">Bio: {@user.bio}</p>
            {#if @current_user && @current_user.id == @user.id}
              <LiveRedirect
                label="Edit"
                to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)}
                class="text-center btn btn-sm btn-primary m-3"
              />
            {/if}
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
