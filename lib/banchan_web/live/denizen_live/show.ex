defmodule BanchanWeb.DenizenLive.Show do
  @moduledoc """
  Banchan denizen profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Accounts
  alias Banchan.Studios

  alias BanchanWeb.Components.{Avatar, Button, Layout, StudioCard}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    user = Accounts.get_user_by_handle!(handle)
    studios = Studios.list_studios_for_user(user)

    {:ok,
     assign(socket,
       user: user,
       studios: studios,
       user_following?:
         socket.assigns.current_user &&
           Accounts.Notifications.user_following?(socket.assigns.current_user, user),
       page_title: "#{user.name} (@#{user.handle})",
       page_description: user.bio,
       page_small_image:
         if user.pfp_thumb_id do
           Routes.public_image_url(Endpoint, :image, user.pfp_thumb_id)
         else
           Routes.static_url(Endpoint, "/images/denizen_default_icon.png")
         end
     )}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event(
        "toggle_follow",
        _,
        %{assigns: %{user_following?: user_following?, user: user, current_user: current_user}} =
          socket
      ) do
    if user_following? do
      Accounts.Notifications.unfollow_user!(user, current_user)
    else
      Accounts.Notifications.follow_user!(user, current_user)
    end

    {:noreply, socket |> assign(user_following?: !user_following?)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <:hero>
        <section class="grid grid-cols-2 bg-secondary">
          <div class="col-span-12">
            <article class="ml-8">
              <Avatar class="w-32" user={@user} />
              <h1 class="text-xl text-base-content font-bold">
                {@user.handle}
              </h1>
              <br>
              <p class="text-base text-secondary-content">
                Witty phrase here.
              </p>
              {#if @current_user}
                <Button click="toggle_follow" class="glass btn-sm rounded-full px-2 py-0">
                  {if @user_following? do
                    "Unfollow"
                  else
                    "Follow"
                  end}
                </Button>
              {/if}
            </article>
          </div>
          <nav class="tabs col-start-2 grid-cols-3 inline-grid">
            <div class="tab tab-bordered tab-active bg-primary-focus text-center rounded-t-lg border-t-6 border-solid border-green-300"><a>Profile Home</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Featured</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Characters</a></div>
          </nav>
        </section>
      </:hero>
      <div class="grid grid-cols-2 justify-items-stretch gap-6">
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
