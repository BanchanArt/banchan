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
          <div :if={!Enum.empty?(@user.tags)} class="mx-6 text-xl">
            Interests
          </div>
          <div :if={!Enum.empty?(@user.tags)} class="mx-6 my-4 flex flex-row flex-wrap gap-1">
            {#for tag <- @user.tags}
              <div class="badge badge-lg gap-2 badge-primary">{tag}</div>
            {/for}
          </div>
          <div class="mx-6 my-4 flex flex-row flex-wrap gap-4">
            <a
              :if={@user.twitter_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://twitter.com/#{@user.twitter_handle}"}
            >
              <i class="fa-brands fa-twitter" /><div class="font-medium text-sm">@{@user.twitter_handle}</div>
            </a>
            <a
              :if={@user.instagram_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://instagram.com/#{@user.instagram_handle}"}
            >
              <i class="fa-brands fa-instagram" /><div class="font-medium text-sm">@{@user.instagram_handle}</div>
            </a>
            <a
              :if={@user.facebook_url}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={@user.facebook_url}
            >
              <i class="fa-brands fa-facebook" />
            </a>
            <a
              :if={@user.furaffinity_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://www.furaffinity.com/user/#{@user.furaffinity_handle}"}
            >
              <img width="16" src={Routes.static_path(Endpoint, "/images/fa-favicon.svg")}><div class="font-medium text-sm">{@user.furaffinity_handle}</div>
            </a>
            <div :if={@user.discord_handle} class="flex flex-row flex-nowrap gap-1 items-center">
              <i class="fa-brands fa-discord" /><div class="font-medium text-sm">{@user.discord_handle}</div>
            </div>
            <a
              :if={@user.artstation_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://artstation.com/#{@user.artstation_handle}"}
            >
              <i class="fa-brands fa-artstation" /><div class="font-medium text-sm">{@user.artstation_handle}</div>
            </a>
            <a
              :if={@user.deviantart_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://www.deviantart.com/#{@user.deviantart_handle}"}
            >
              <i class="fa-brands fa-deviantart" /><div class="font-medium text-sm">{@user.deviantart_handle}</div>
            </a>
            <a
              :if={@user.tumblr_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://www.tumblr.com/blog/#{@user.tumblr_handle}"}
            >
              <i class="fa-brands fa-tumblr" /><div class="font-medium text-sm">{@user.tumblr_handle}</div>
            </a>
            <a
              :if={@user.twitch_channel}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://www.twitch.tv/#{@user.twitch_channel}"}
            >
              <i class="fa-brands fa-twitch" /><div class="font-medium text-sm">{@user.twitch_channel}</div>
            </a>
            <a
              :if={@user.pixiv_handle && @user.pixiv_url}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={@user.pixiv_url}
            >
              <img width="16" src={Routes.static_path(Endpoint, "/images/pixiv-favicon.svg")}><div class="font-medium text-sm">{@user.pixiv_handle}</div>
            </a>
            <a
              :if={@user.picarto_channel}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://picarto.tv/#{@user.picarto_channel}"}
            >
              <img width="16" src={Routes.static_path(Endpoint, "/images/picarto-favicon.svg")}><div class="font-medium text-sm">{@user.pixiv_handle}</div>
            </a>
            <a
              :if={@user.tiktok_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://www.tiktok.com/@#{@user.tiktok_handle}"}
            >
              <i class="fa-brands fa-tiktok" /><div class="font-medium text-sm">@{@user.tiktok_handle}</div>
            </a>
            <a
              :if={@user.artfight_handle}
              class="flex flex-row flex-nowrap gap-1 items-center"
              href={"https://artfight.net/~#{@user.artfight_handle}"}
            >
              <img width="16" src={Routes.static_path(Endpoint, "/images/artfight-favicon.svg")}><div class="font-medium text-sm">~{@user.artfight_handle}</div>
            </a>
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
