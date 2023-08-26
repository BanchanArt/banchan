defmodule BanchanWeb.PeopleLive.Show do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :live_view

  alias Banchan.Accounts
  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias Banchan.Utils

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias BanchanWeb.Components.{
    Avatar,
    Icon,
    InfiniteScroll,
    Layout,
    Modal,
    ReportModal,
    Socials,
    StudioCard,
    Tag,
    UserHandle
  }

  alias BanchanWeb.Endpoint

  @impl true
  def handle_params(%{"handle" => handle}, _uri, socket) do
    user = Accounts.get_user_by_handle!(handle)
    socket = socket |> assign(user: user)

    {:noreply,
     assign(socket,
       studios: list_studios(socket),
       following: Studios.Notifications.following_count(user),
       page_title: "#{user.name} (@#{user.handle})",
       page_description: user.bio,
       page_small_image:
         if user.pfp_img_id do
           Routes.public_image_url(Endpoint, :image, :user_pfp_img, user.pfp_img_id)
         else
           Routes.static_url(Endpoint, "/images/user_default_icon.png")
         end
     )}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.studios.total_entries >
         socket.assigns.studios.page_number * socket.assigns.studios.page_size do
      {:noreply, fetch_results(socket.assigns.studios.page_number + 1, socket)}
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
      ~p"/people/#{socket.assigns.user.handle}"
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
          with_follower: socket.assigns.user,
          page_size: 24,
          page: page
        )
    end
  end

  defp fetch_results(page, %{assigns: %{studios: studios}} = socket) do
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
    <Layout flashes={@flash}>
      <:hero>
        <section>
          {#if @user.header_img && !@user.header_img.pending && !@user.disable_info}
            <img
              class="object-cover w-full aspect-header-image max-h-80"
              src={Routes.public_image_path(Endpoint, :image, :user_header_img, @user.header_img_id)}
            />
          {#else}
            <div class="w-full max-h-80 aspect-header-image bg-base-300" />
          {/if}
          <div class="flex flex-col items-start w-full gap-0 mx-auto max-w-7xl">
            <div class="flex flex-row flex-wrap w-full">
              <div class="relative w-32 h-20">
                <div class="absolute -top-4 left-6">
                  {#if @user.disable_info}
                    <div class="avatar">
                      <div class="rounded-full">
                        <div class="w-24 h-24 bg-base-300" />
                      </div>
                    </div>
                  {#else}
                    <Avatar thumb={false} class="w-24 h-24" user={@user} />
                  {/if}
                </div>
              </div>
              <div class="hidden m-4 md:flex md:flex-col">
                <h1 class="text-xl font-bold">
                  {#if !@user.disable_info}
                    {@user.name}
                  {/if}
                </h1>
                <UserHandle link={false} user={@user} />
              </div>
              <div class="flex flex-row gap-2 m-4 ml-auto place-content-end">
                {#if @current_user && (@current_user.id != @user.id || Accounts.mod?(@current_user))}
                  <div class="dropdown dropdown-end">
                    <label tabindex="0" class="py-0 my-2 btn btn-circle btn-outline btn-sm grow-0">
                      <Icon name="more-vertical" size="4" />
                    </label>
                    <ul
                      tabindex="0"
                      class="p-2 border menu md:menu-compact dropdown-content bg-base-300 border-base-content border-opacity-10 rounded-box"
                    >
                      {#if Accounts.mod?(@current_user)}
                        <li>
                          <LiveRedirect to={~p"/people/#{@user.handle}/moderation"}>
                            <Icon name="gavel" size="4" /> Moderation
                          </LiveRedirect>
                        </li>
                      {/if}
                      <li>
                        <button type="button" :on-click="open_block_modal">
                          <Icon name="circle-slash" size="4" /> Block
                        </button>
                      </li>
                      <li>
                        <button type="button" :on-click="open_unblock_modal">
                          <Icon name="user-plus" size="4" /> Unblock
                        </button>
                      </li>
                      <li>
                        <button type="button" :on-click="report">
                          <Icon name="flag" size="4" /> Report
                        </button>
                      </li>
                    </ul>
                  </div>
                {/if}
                {#if @current_user &&
                    (@current_user.id == @user.id || Accounts.mod?(@current_user))}
                  <LiveRedirect
                    label="Edit Profile"
                    to={~p"/people/#{@user.handle}/edit"}
                    class="px-2 py-0 m-2 rounded-full btn btn-sm btn-primary grow-0"
                  />
                {/if}
              </div>
            </div>
            <div class="flex flex-col w-full m-4 mx-8 md:hidden">
              {#if !@user.disable_info}
                <h1 class="text-xl font-bold">
                  {@user.name}
                </h1>
              {/if}
              <UserHandle link={false} user={@user} />
            </div>
            {#if !@user.disable_info && @user.bio}
              <div class="w-full mx-6 my-4">
                {@user.bio}
              </div>
            {/if}
            {#if !@user.disable_info && !Enum.empty?(@user.tags)}
              <div class="flex flex-row flex-wrap w-full gap-1 mx-6 my-4">
                {#for tag <- @user.tags}
                  <Tag tag={tag} />
                {/for}
              </div>
            {/if}
            {#if Utils.has_socials?(@user)}
              <Socials entity={@user} class="my-4 mx-6" />
            {/if}
            <div class="flex flex-row gap-4 mx-6 my-4">
              <LivePatch class="hover:link" to={~p"/people/#{@user.handle}/following"}>
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
          </div>
          <div class="w-full border-t h-fit border-base-content border-opacity-10" />
        </section>
      </:hero>
      <div class="flex flex-col items-start w-full gap-4 px-4 mx-auto max-w-7xl">
        {#if @user.disable_info}
          <div class="font-semibold">This account has been disabled.</div>
        {#else}
          {#if !Enum.empty?(@studios)}
            {#if @live_action == :show}
              <div class="pb-2 text-2xl">Artist for:</div>
            {#elseif @live_action == :following}
              <div class="pb-2 text-2xl">Following:</div>
            {/if}
            <div class="grid grid-cols-1 gap-4 studio-list sm:grid-cols-2 md:grid-cols-3 auto-rows-fr">
              {#for studio <- @studios}
                <StudioCard studio={studio} />
              {/for}
            </div>
            <InfiniteScroll id="studios-infinite-scroll" page={@studios.page_number} load_more="load_more" />
          {/if}
        {/if}
      </div>

      <Modal id="block-modal">
        <:title>Block From...</:title>
        <ul class="p-2 overflow-auto menu">
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
        <ul class="p-2 overflow-auto menu">
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
