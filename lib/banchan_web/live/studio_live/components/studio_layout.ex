defmodule BanchanWeb.StudioLive.Components.StudioLayout do
  @moduledoc """
  Shared layout component between the various Studio-related pages.
  """
  use BanchanWeb, :live_component

  alias Banchan.Accounts
  alias Banchan.Studios
  alias Banchan.Utils

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Avatar, Button, Icon, Layout, ReportModal, Socials, Tag}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.{FeaturedToggle, FollowerCountLive, TabButton}

  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop studio, :struct, required: true
  prop tab, :atom
  prop padding, :integer
  prop flashes, :any, required: true

  data follower_count, :integer, from_context: :follower_count
  data user_following?, :boolean

  slot default

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      if is_nil(socket.assigns[:user_following?]) && socket.assigns.current_user do
        socket
        |> assign(
          user_following?:
            Studios.Notifications.user_following?(
              socket.assigns.current_user,
              socket.assigns.studio
            )
        )
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event(
        "toggle_follow",
        _,
        %{
          assigns: %{user_following?: user_following?, studio: studio, current_user: current_user}
        } = socket
      ) do
    if user_following? do
      Studios.Notifications.unfollow_studio!(studio, current_user)
    else
      Studios.Notifications.follow_studio!(studio, current_user)
    end

    {:noreply, socket |> assign(user_following?: !user_following?)}
  end

  def handle_event("report", _, socket) do
    ReportModal.show(
      socket.assigns.id <> "-report-modal",
      Routes.studio_shop_url(Endpoint, :show, socket.assigns.studio.handle)
    )

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Layout
      flashes={@flashes}
      padding={@padding}
      studio={@studio}
      context={if @current_user_member? do
        :studio
      else
        :client
      end}
    >
      <:hero>
        <section>
          {#if @studio.header_img && !@studio.header_img.pending && !@studio.disable_info}
            <img
              class="object-cover w-full aspect-header-image max-h-80"
              src={Routes.public_image_path(Endpoint, :image, :studio_header_img, @studio.header_img_id)}
            />
          {#else}
            <div class="w-full max-h-80 aspect-header-image bg-base-300" />
          {/if}
          <div class="px-4 mx-auto my-4 max-w-7xl">
            <div class="flex flex-row gap-2">
              <div class="text-2xl font-medium md:text-3xl grow">
                {@studio.name}
              </div>
              {#if @current_user && (Accounts.mod?(@current_user) || !@current_user_member?)}
                <div class="dropdown dropdown-end">
                  <label tabindex="0" class="py-0 my-2 btn btn-circle btn-ghost btn-sm grow-0">
                    <Icon name="more-vertical" size="4" />
                  </label>
                  <ul
                    tabindex="0"
                    class="p-1 border rounded-xl dropdown-content bg-base-300 border-base-content border-opacity-10 menu md:menu-compact"
                  >
                    {#if Accounts.mod?(@current_user)}
                      <li>
                        <LiveRedirect to={Routes.studio_moderation_path(Endpoint, :edit, @studio.handle)}>
                          <Icon name="gavel" size="4" /> Moderation
                        </LiveRedirect>
                      </li>
                    {/if}
                    {#if Accounts.admin?(@current_user)}
                      <li>
                        <FeaturedToggle id="featured-toggle" current_user={@current_user} studio={@studio} />
                      </li>
                    {/if}
                    <li>
                      <button type="button" :on-click="report">
                        <Icon name="flag" size="4" /> Report
                      </button>
                    </li>
                  </ul>
                </div>
              {/if}
              {#if @current_user && !@current_user_member?}
                <Button click="toggle_follow" class="px-2 py-0 my-2 ml-auto rounded-full btn-sm btn-primary">
                  {if @user_following? do
                    "Unfollow"
                  else
                    "Follow"
                  end}
                </Button>
              {/if}
              {#if @current_user_member? ||
                  (@current_user && (:admin in @current_user.roles || :mod in @current_user.roles))}
                <LiveRedirect
                  label="Edit Profile"
                  to={Routes.studio_edit_path(Endpoint, :edit, @studio.handle)}
                  class="px-2 py-0 my-2 rounded-full btn btn-sm btn-primary grow-0"
                />
              {/if}
            </div>
            {#if Utils.has_socials?(@studio)}
              <Socials entity={@studio} class="my-4" />
            {/if}
            <div class="flex flex-row items-center gap-1">
              <span>By</span>
              <div class="-space-x-6 transition-all avatar-group hover:space-x-0">
                {#for member <- @studio.artists}
                  <Avatar user={member} class="w-8" />
                {/for}
              </div>
              <div class="p-2">|</div>
              <FollowerCountLive id="follower-count" session={%{"handle" => @studio.handle}} />
            </div>
            <p class="pt-4">
              {@studio.about}
            </p>
            <div :if={!Enum.empty?(@studio.tags)} class="flex flex-row flex-wrap gap-1 my-2">
              {#for tag <- @studio.tags}
                <Tag tag={tag} type="studios" />
              {/for}
            </div>
          </div>
          <div class="flex flex-row items-end gap-0">
            <div class="p-0 mt-auto mb-0 h-fit divider grow" />
            <div class="w-full mx-auto overflow-auto max-w-7xl">
              <div class="flex w-full tabs flex-nowrap">
                <TabButton
                  label="Shop"
                  tab_name={:shop}
                  current_tab={@tab}
                  to={Routes.studio_shop_path(Endpoint, :show, @studio.handle)}
                />
                <TabButton
                  label="Portfolio"
                  tab_name={:portfolio}
                  current_tab={@tab}
                  to={Routes.studio_portfolio_path(Endpoint, :show, @studio.handle)}
                />
              </div>
            </div>
            <div class="p-0 mt-auto mb-0 h-fit divider grow" />
          </div>
        </section>
      </:hero>
      <#slot />
      {#if @current_user}
        <ReportModal id={@id <> "-report-modal"} current_user={@current_user} />
      {/if}
    </Layout>
    """
  end
end
