defmodule BanchanWeb.StudioLive.Components.StudioLayout do
  @moduledoc """
  Shared layout component between the various Studio-related pages.
  """
  use BanchanWeb, :live_component

  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Button, Layout}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.{FeaturedToggle, TabButton}

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop flashes, :string, required: true
  prop studio, :struct, required: true
  prop followers, :integer, required: true
  prop tab, :atom
  prop uri, :string, required: true
  prop padding, :integer

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

  def render(assigns) do
    ~F"""
    <Layout uri={@uri} padding={@padding} current_user={@current_user} flashes={@flashes}>
      <:hero>
        <section>
          {#if @studio.header_img && !@studio.header_img.pending && !@studio.disable_info}
            <img
              class="object-cover aspect-header-image rounded-b-xl w-full"
              src={Routes.public_image_path(Endpoint, :image, @studio.header_img_id)}
            />
          {#else}
            <div class="rounded-b-xl aspect-header-image bg-base-300 w-full" />
          {/if}
          <div class="m-6">
            <h1 class="font-medium text-2xl md:text-3xl flex flex-row gap-2">
              <div class="grow">
                {@studio.name}
              </div>
              {#if @current_user && (:admin in @current_user.roles || :mod in @current_user.roles)}
                <LiveRedirect
                  label="Moderation"
                  to={Routes.studio_moderation_path(Endpoint, :edit, @studio.handle)}
                  class="btn btn-sm btn-warning rounded-full px-2 py-0 m-1"
                />
              {/if}
              {#if @current_user && :admin in @current_user.roles}
                <FeaturedToggle id="featured-toggle" current_user={@current_user} studio={@studio} />
              {/if}
              {#if @current_user}
                <Button click="toggle_follow" class="ml-auto btn-sm btn-outline rounded-full px-2 py-0">
                  {if @user_following? do
                    "Unfollow"
                  else
                    "Follow"
                  end}
                </Button>
              {/if}
            </h1>
            <div :if={!Enum.empty?(@studio.tags)} class="my-2 flex flex-row flex-wrap gap-1">
              {#for tag <- @studio.tags}
                <div class="badge badge-lg gap-2 badge-primary cursor-default">{tag}</div>
              {/for}
            </div>
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
          </div>
          <div class="overflow-auto min-w-screen">
            <nav class="tabs px-2 flex flex-nowrap">
              <TabButton
                label="Shop"
                tab_name={:shop}
                current_tab={@tab}
                to={Routes.studio_shop_path(Endpoint, :show, @studio.handle)}
              />
              <TabButton
                label="About"
                tab_name={:about}
                current_tab={@tab}
                to={Routes.studio_about_path(Endpoint, :show, @studio.handle)}
              />
              <TabButton
                label="Portfolio"
                tab_name={:portfolio}
                current_tab={@tab}
                to={Routes.studio_portfolio_path(Endpoint, :show, @studio.handle)}
              />
              {#if @current_user_member?}
                <TabButton
                  label="Payouts"
                  tab_name={:payouts}
                  current_tab={@tab}
                  to={Routes.studio_payouts_path(Endpoint, :index, @studio.handle)}
                />

                <TabButton
                  label="Settings"
                  tab_name={:settings}
                  current_tab={@tab}
                  to={Routes.studio_settings_path(Endpoint, :show, @studio.handle)}
                />
              {/if}
            </nav>
          </div>
        </section>
      </:hero>
      <#slot />
    </Layout>
    """
  end
end
