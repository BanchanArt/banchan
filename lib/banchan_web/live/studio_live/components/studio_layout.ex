defmodule BanchanWeb.StudioLive.Components.StudioLayout do
  @moduledoc """
  Shared layout component between the various Studio-related pages.
  """
  use BanchanWeb, :live_component

  alias Banchan.Studios

  alias BanchanWeb.Components.{Button, Layout}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.TabButton

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop flashes, :string, required: true
  prop studio, :struct, required: true
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
        <section class="bg-secondary">
          <div class="ml-8 col-span-12">
            <p class="text-3xl text-secondary-content font-bold flex-grow">
              {@studio.name}
            </p>
            <p class="text-base text-secondary-content flex-grow">
              {@studio.description}
              {#if @current_user}
                <Button click="toggle_follow" class="glass btn-sm rounded-full px-2 py-0">
                  {if @user_following? do
                    "Unfollow"
                  else
                    "Follow"
                  end}
                </Button>
              {/if}
            </p>
            <br>
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
