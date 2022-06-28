defmodule BanchanWeb.DenizenLive.Show do
  @moduledoc """
  Banchan denizen profile pages
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts
  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Avatar, Button, Layout}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    user = Accounts.get_user_by_handle!(handle)
    studios = Studios.list_studios_for_user(user)

    {:ok,
     assign(socket,
       user: user,
       studios: studios,
       followers: Accounts.Notifications.follower_count(user),
       following: Accounts.Notifications.following_count(user),
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
        %{assigns: %{user: user, current_user: current_user}} = socket
      )
      when user.id == current_user.id do
    {:noreply, socket}
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
        <section>
          {#if @user.header_img_id}
            <img
              class="object-cover aspect-header-image rounded-b-xl w-full"
              src={Routes.public_image_path(Endpoint, :image, @user.header_img_id)}
            />
          {#else}
            <div class="rounded-b-xl aspect-header-image bg-base-300 w-full" />
          {/if}
          <div class="flex flex-row">
            <div class="relative w-32 h-20">
              <div class="absolute -top-4 left-6">
                <Avatar class="w-24 h-24" user={@user} />
              </div>
            </div>
            <div class="m-4 flex flex-col">
              <h1 class="text-xl font-bold">
                {@user.name}
              </h1>
              <span>@{@user.handle}</span>
            </div>
            {#if @current_user && @current_user.id == @user.id}
              <LiveRedirect
                label="Edit Profile"
                to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)}
                class="btn btn-sm btn-primary btn-outline m-4 ml-auto rounded-full px-2 py-0"
              />
            {#else}
              <Button click="toggle_follow" class="btn-sm btn-outline m-4 ml-auto rounded-full px-2 py-0">
                {if @user_following? do
                  "Unfollow"
                else
                  "Follow"
                end}
              </Button>
            {/if}
          </div>
          <div class="mx-6 my-4">
            {@user.bio}
          </div>
          <div :if={!Enum.empty?(@user.tags)} class="mx-6 my-4 flex flex-col flex-wrap">
            {#for tag <- @user.tags}
              <div class="badge">#{tag}</div>
            {/for}
          </div>
          <div class="mx-6 flex flex-row my-4 gap-4">
            <div>
              <span class="font-bold">
                {#if @followers > 9999}
                  {Number.SI.number_to_si(@followers)}
                {#else}
                  {Number.Delimit.number_to_delimited(@followers, precision: 0)}
                {/if}
              </span>
              <span>
                {#if @followers == 1}
                  Follower
                {#else}
                  Followers
                {/if}
              </span>
            </div>
            <div>
              <span class="font-bold">
                {#if @following > 9999}
                  {Number.SI.number_to_si(@following)}
                {#else}
                  {Number.Delimit.number_to_delimited(@following, precision: 0)}
                {/if}
              </span>
              <span>
                Following
              </span>
            </div>
          </div>
        </section>
      </:hero>
    </Layout>
    """
  end
end
