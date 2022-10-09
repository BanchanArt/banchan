defmodule BanchanWeb.StudioLive.Followers do
  @moduledoc """
  LiveView for the studio followers listing.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios.Notifications

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.{Avatar, Card, InfiniteScroll, UserHandle}
  alias BanchanWeb.StudioLive.Components.StudioLayout

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)
    socket = socket |> assign(followers: Notifications.list_followers(socket.assigns.studio))

    {:ok, socket}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.followers.total_entries >
         socket.assigns.followers.page_number * socket.assigns.followers.page_size do
      {:noreply, fetch(socket.assigns.followers.page_number + 1, socket)}
    else
      {:noreply, socket}
    end
  end

  defp fetch(page, %{assigns: %{followers: followers, studio: studio}} = socket) do
    socket
    |> assign(
      :followers,
      %{
        followers
        | page_number: page,
          entries: followers.entries ++ Notifications.list_followers(studio, page: page).entries
      }
    )
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout flash={@flash} id="studio-layout" studio={@studio}>
      <h3 class="p-6 text-semibold text-2xl">Followers</h3>
      <ul class="grid sm:px-2 grid grid-cols-2 sm:gap-2 sm:grid-cols-4 auto-rows-fr">
        {#for user <- @followers}
          <li>
            <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, user.handle)}>
              <Card image_class="aspect-header-image">
                <:image>
                  {#if user.header_img && !user.header_img.pending}
                    <img
                      class="object-cover aspect-header-image w-full"
                      src={Routes.public_image_path(Endpoint, :image, :user_header_img, user.header_img_id)}
                    />
                  {#else}
                    <div class="aspect-header-image bg-base-300 w-full" />
                  {/if}
                </:image>
                <div class="flex flex-row flex-wrap">
                  <div class="relative w-16 h-6">
                    <div class="absolute -top-8 left-2">
                      <Avatar link={false} class="w-12 h-12" user={user} />
                    </div>
                  </div>
                  <div>
                    <h1 class="text-xl font-bold">
                      {user.name}
                    </h1>
                    <UserHandle link={false} user={user} />
                  </div>
                </div>
              </Card>
            </LiveRedirect>
          </li>
        {/for}
      </ul>
      <InfiniteScroll
        id="followers-infinite-scroll"
        page={@followers.page_number}
        load_more="load_more"
      />
    </StudioLayout>
    """
  end
end
