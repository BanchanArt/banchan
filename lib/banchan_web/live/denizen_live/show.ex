defmodule BanchanWeb.DenizenLive.Show do
  @moduledoc """
  Banchan denizen profile pages
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts
  alias Banchan.Studios
  alias Banchan.Studios.Studio

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias BanchanWeb.Components.{
    Avatar,
    InfiniteScroll,
    Layout,
    Modal,
    ReportModal,
    StudioCard,
    Tag
  }

  alias BanchanWeb.Endpoint

  @impl true
  def handle_params(%{"handle" => handle}, uri, socket) do
    user = Accounts.get_user_by_handle!(handle)
    socket = socket |> assign(user: user)

    {:noreply,
     assign(socket,
       uri: uri,
       studios: list_studios(socket),
       following: Studios.Notifications.following_count(user),
       page_title: "#{user.name} (@#{user.handle})",
       page_description: user.bio,
       page_small_image:
         if user.pfp_img_id do
           Routes.public_image_url(Endpoint, :image, :user_pfp_img, user.pfp_img_id)
         else
           Routes.static_url(Endpoint, "/images/denizen_default_icon.png")
         end
     )}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.studios.total_entries >
         socket.assigns.studios.page_number * socket.assigns.studios.page_size do
      {:noreply, fetch(socket.assigns.studios.page_number + 1, socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_block_modal", _, socket) do
    socket =
      socket
      |> assign(
        blockable_studios:
          Studios.blockable_studios(socket.assigns.current_user, socket.assigns.user)
      )

    Modal.show("block-modal")
    {:noreply, socket}
  end

  @impl true
  def handle_event("block_user", %{"from" => studio_id}, socket) do
    {studio_id, ""} = Integer.parse(studio_id)

    {:ok, _} =
      Studios.block_user(
        socket.assigns.current_user,
        %Studio{id: studio_id},
        socket.assigns.user,
        %{
          reason: "manual block from user profile"
        }
      )

    Modal.hide("block-modal")
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_unblock_modal", _, socket) do
    socket =
      socket
      |> assign(
        unblockable_studios:
          Studios.unblockable_studios(socket.assigns.current_user, socket.assigns.user)
      )

    Modal.show("unblock-modal")
    {:noreply, socket}
  end

  @impl true
  def handle_event("unblock_user", %{"from" => studio_id}, socket) do
    {studio_id, ""} = Integer.parse(studio_id)
    Studios.unblock_user(socket.assigns.current_user, %Studio{id: studio_id}, socket.assigns.user)
    Modal.hide("unblock-modal")
    {:noreply, socket}
  end

  @impl true
  def handle_event("report", _, socket) do
    ReportModal.show(
      "report-modal",
      Routes.denizen_show_url(Endpoint, :show, socket.assigns.user.handle)
    )

    {:noreply, socket}
  end

  defp list_studios(socket, page \\ 1) do
    case socket.assigns.live_action do
      :show ->
        Studios.list_studios(
          current_user: socket.assigns.current_user,
          with_member: socket.assigns.user,
          page_size: 24,
          page: page
        )

      :following ->
        Studios.list_studios(
          current_user: socket.assigns.current_user,
          with_follower: socket.assigns.current_user,
          page_size: 24,
          page: page
        )
    end
  end

  defp fetch(page, %{assigns: %{studios: studios}} = socket) do
    socket
    |> assign(
      :studios,
      %{
        studios
        | page_number: page,
          entries: studios.entries ++ list_studios(socket, page).entries
      }
    )
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <:hero>
        <section>
          {#if @user.header_img && !@user.header_img.pending && !@user.disable_info}
            <img
              class="object-cover aspect-header-image rounded-b-xl w-full"
              src={Routes.public_image_path(Endpoint, :image, :user_header_img, @user.header_img_id)}
            />
          {#else}
            <div class="rounded-b-xl aspect-header-image bg-base-300 w-full" />
          {/if}
          <div class="flex flex-row">
            <div class="relative w-32 h-20">
              <div class="absolute -top-4 left-6">
                {#if @user.disable_info}
                  <div class="avatar">
                    <div class="rounded-full">
                      <div class="bg-base-300 w-24 h-24" />
                    </div>
                  </div>
                {#else}
                  <Avatar thumb={false} class="w-24 h-24" user={@user} />
                {/if}
              </div>
            </div>
            <div class="m-4 flex flex-col">
              <h1 class="text-xl font-bold">
                {#if !@user.disable_info}
                  {@user.name}
                {/if}
              </h1>
              <span>@{@user.handle}</span>
            </div>
            <div class="flex flex-row gap-2 place-content-end ml-auto m-4">
              {#if @current_user}
                <div class="dropdown dropdown-end">
                  <label tabindex="0" class="btn btn-circle btn-outline btn-sm my-2 py-0 grow-0">
                    <i class="fas fa-ellipsis-vertical" />
                  </label>
                  <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-200 rounded-box">
                    {#if @current_user && (:admin in @current_user.roles || :mod in @current_user.roles)}
                      <li>
                        <LiveRedirect to={Routes.denizen_moderation_path(Endpoint, :edit, @user.handle)}>
                          <i class="fas fa-gavel" /> Moderation
                        </LiveRedirect>
                      </li>
                    {/if}
                    <li>
                      <button type="button" :on-click="open_block_modal">
                        <i class="fas fa-ban" /> Block
                      </button>
                    </li>
                    <li>
                      <button type="button" :on-click="open_unblock_modal">
                        <i class="fa-solid fa-handshake" /> Unblock
                      </button>
                    </li>
                    <li>
                      <button type="button" :on-click="report">
                        <i class="fas fa-flag" /> Report
                      </button>
                    </li>
                  </ul>
                </div>
              {/if}
              {#if @current_user &&
                  (@current_user.id == @user.id || :admin in @current_user.roles || :mod in @current_user.roles)}
                <LiveRedirect
                  label="Edit Profile"
                  to={Routes.denizen_edit_path(Endpoint, :edit, @user.handle)}
                  class="btn btn-sm btn-primary btn-outline rounded-full m-2 px-2 py-0 grow-0"
                />
              {/if}
            </div>
          </div>
          <div class="mx-6 my-4">
            {#if !@user.disable_info}
              {@user.bio}
            {/if}
          </div>
          <div
            :if={!@user.disable_info && !Enum.empty?(@user.tags)}
            class="mx-6 my-4 flex flex-row flex-wrap gap-1"
          >
            {#for tag <- @user.tags}
              <Tag tag={tag} />
            {/for}
          </div>
          <div :if={!@user.disable_info} class="mx-6 my-4 flex flex-row flex-wrap gap-4">
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
            <LivePatch class="hover:link" to={Routes.denizen_show_path(Endpoint, :following, @user.handle)}>
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
            </LivePatch>
          </div>
        </section>
      </:hero>
      {#if @user.disable_info}
        <div class="font-semibold">This account has been disabled.</div>
      {#else}
        {#if !Enum.empty?(@studios)}
          {#if @live_action == :show}
            <div class="text-2xl pb-6">Artist for:</div>
          {#elseif @live_action == :following}
            <div class="text-2xl pb-6">Following:</div>
          {/if}
          <div class="studio-list grid grid-cols-1 sm:gap-2 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 auto-rows-fr">
            {#for studio <- @studios}
              <StudioCard studio={studio} />
            {/for}
          </div>
          <InfiniteScroll id="studios-infinite-scroll" page={@studios.page_number} load_more="load_more" />
        {/if}
      {/if}

      <Modal id="block-modal">
        <:title>Block From...</:title>
        <ul class="overflow-auto menu p-2">
          {#for studio <- @blockable_studios}
            <li>
              <button type="button" :on-click="block_user" phx-value-from={studio.id}>
                {studio.name}
              </button>
            </li>
          {/for}
        </ul>
      </Modal>
      <Modal id="unblock-modal">
        <:title>Unblock From...</:title>
        <ul class="overflow-auto menu p-2">
          {#for studio <- @unblockable_studios}
            <li>
              <button type="button" :on-click="unblock_user" phx-value-from={studio.id}>
                {studio.name}
              </button>
            </li>
          {/for}
        </ul>
      </Modal>
      {#if @current_user}
        <ReportModal id="report-modal" current_user={@current_user} />
      {/if}
    </Layout>
    """
  end
end
